#!/bin/bash

user_id=$(id -u)

logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
DOMAIN_NAME="usdaws92s.store"
scripts_dir=$(dirname "$(realpath "$0")")
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

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "NodeJS installation"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Roboshop system user creation"
else
    echo -e "$(timestamp) [INFO] Roboshop system user already exists...${Y}SKIPPING${N}" | tee -a "$logs_file"
fi  

rm -rf /app &>> $logs_file
validate $? "Roboshop application folder cleanup"

mkdir -p /app
validate $? "Roboshop application folder creation"

curl -L -o /tmp/user.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/user-v4.zip
validate $? "Roboshop user artifact download"

cd /app
unzip /tmp/user.zip &>> $logs_file
validate $? "Roboshop user artifact unzip"

npm install &>> $logs_file
validate $? "Roboshop user dependencies installation"

sed -i -e "s/DOMAIN_NAME/${DOMAIN_NAME}/" "$scripts_dir/user.service" &>> "$logs_file"
validate $? "User service configuration"

cp "$scripts_dir/user.service" /etc/systemd/system/user.service &>> "$logs_file"
validate $? "Roboshop user systemd service file setup"

systemctl daemon-reload &>> $logs_file
systemctl enable user &>> $logs_file
systemctl start user &>> $logs_file
validate $? "Enable and start Roboshop user service"


systemctl restart user &>> $logs_file
validate $? "Roboshop user service restart"

echo "$(timestamp) [INFO] time taken $SECONDS"
echo "$(timestamp) [INFO] ====== Script completed execution ======" | tee -a "$logs_file"