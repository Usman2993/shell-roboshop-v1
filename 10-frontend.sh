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

dnf module disable nginx -y &>> $logs_file
dnf module enable nginx:1.26 -y &>> $logs_file
dnf install nginx -y
validate $? "Nginx installation"

systemctl enable nginx &>> $logs_file
systemctl start nginx &>> $logs_file
validate $? "Enable and start Nginx"

rm -rf /usr/share/nginx/html/*
validate $? "Nginx default content cleanup"

curl -L -o /tmp/frontend.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/frontend-v4.zip
cd /usr/share/nginx/html &>> $logs_file
unzip /tmp/frontend.zip &>> $logs_file
validate $? "Roboshop frontend artifact unzip"

sed -i -e "s/DOMAIN_NAME/${DOMAIN_NAME}/" "$scripts_dir/roboshop.conf" &>> "$logs_file"
validate $? "Frontend configuration"

cp "$scripts_dir/roboshop.conf" /etc/nginx/default.d/roboshop.conf &>> "$logs_file"
validate $? "Roboshop frontend configuration file setup"

nginx -t &>> $logs_file
validate $? "Nginx configuration test"

systemctl restart nginx &>> $logs_file
validate $? "Nginx service restart"


echo "$(timestamp) [INFO] time taken $SECONDS"
echo "$(timestamp) [INFO] ====== Script completed execution ======" | tee -a "$logs_file"