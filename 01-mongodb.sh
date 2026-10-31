#!/bin/bash

user_id=$(id -u)

logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "Please run the script with sudo access"
    exit 1   
fi


mkdir -p $logs_folder

echo "Script started execution at $(date +"%F %T")"

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "${2}..${R} failed${N}" | tee -a "$logs_file"
        exit 1
    else 
        echo -e "${2}..${G} successful${N}" | tee -a "$logs_file"
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> $logs_file
validate $? "MongoDB repo setup"

dnf install mongodb-org -y
validate $? "MongoDB installation"

systemctl enable mongod
systemctl start mongod
validate $? "Enable and start MongoDB"


sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
validate $? "MongoDB bind address change"

systemctl restart mongod
validate $? "MongoDB restart"