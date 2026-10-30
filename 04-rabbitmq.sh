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

#echo "Script started execution at $(date +"%F %T")"

timestamp(){
    date +"%F %T"       
}

validate(){
    if [ $1 -ne 0 ]; then
        echo -e "$(timestamp) [ERROR] ${2}..${R} failed${N}" | tee -a "$logs_file"
        exit 1
    else 
        echo -e "$(timestamp) [INFO] ${2}..${G} successful${N}" | tee -a "$logs_file"
    fi
}

echo "$(timestamp) [INFO] ====== Script started execution ======" | tee -a "$logs_file"

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $logs_file
validate $? "RabbitMQ repo setup"

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "RabbitMQ installation"

systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "Enable and start RabbitMQ"

rabbitmqctl add_user roboshop roboshop123 &>> $logs_file
validate $? "RabbitMQ user creation"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "RabbitMQ user setup"


echo "$(timestamp) [INFO] time taken $SECONDS"
echo "$(timestamp) [INFO] ====== Script completed execution ======" | tee -a "$logs_file"