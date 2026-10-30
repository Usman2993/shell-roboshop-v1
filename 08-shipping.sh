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

dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Maven and Java installation"

alternatives --set java "//usr/lib/jvm/java-25-openjdk/bin/java" &>> $logs_file
validate $? "Java alternatives setup java 25 as default"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh
source /etc/profile.d/java.sh
echo $JAVA_HOME
validate $? "setting JAVA_HOME for maven"

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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip
validate $? "Roboshop shipping artifact download"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "Roboshop shipping artifact unzip"

mvn clean package &>> $logs_file
validate $? "Roboshop user dependencies installation"

mv target/shipping.jar shipping.jar
validate $? "Roboshop shipping jar rename"

sed -i -e "s/DOMAIN_NAME/${DOMAIN_NAME}/" "$scripts_dir/shipping.service" &>> "$logs_file"
validate $? "User service configuration"

cp "$scripts_dir/shipping.service" /etc/systemd/system/shipping.service &>> "$logs_file"
validate $? "Roboshop user systemd service file setup"

dnf install mysql -y &>> $logs_file
validate $? "MySQL client installation"

count=$(mysql -h "mysql.$DOMAIN_NAME" -uroot -pRoboShop@1 -N -B -e "SELECT COUNT(*) FROM cities.cities;" 2>> $logs_file)
if [ -z "$count" ] || [ "$count" -eq 0 ]; then
    mysql -h "mysql.$DOMAIN_NAME" -uroot -pRoboShop@1 < /app/db/master-data.sql
    validate $? "Roboshop shipping database setup"
else
echo -e "$(timestamp) [INFO] master database already exists...${Y}SKIPPING${N}" | tee -a "$logs_file"
fi    

mysql -h "mysql.$DOMAIN_NAME" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "creating app user setup"

systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl start shipping &>> $logs_file
validate $? "Enable and start Roboshop shipping service"


systemctl restart shipping &>> $logs_file
validate $? "Roboshop user service restart"


echo "$(timestamp) [INFO] time taken $SECONDS"
echo "$(timestamp) [INFO] ====== Script completed execution ======" | tee -a "$logs_file"