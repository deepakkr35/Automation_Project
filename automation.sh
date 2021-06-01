#!/bin/bash

#initializes all the variables
myname="deepak_kumar"
timestamp=$(date '+%d%m%Y-%H%M%S')
s3_bucket="upgrad-deepak-kumar"

#Update the package details
apt update -y

#Checks whether the HTTP Apache server is already installed. If not present, then it installs the server
if [ $(dpkg-query -W -f='${Status}' apache2 | grep -c "ok installed") -eq 0 ];
then
  apt-get install apache2
fi

#Checks whether the server is running or not. If it is not running, then it starts the server
if [ $(systemctl status apache2 | grep Active | grep -c "active (running)") -eq 0 ];
then
  systemctl start apache2
fi

#Checks whether the service is enabled or not. It enables the service if not enabled already
if [ $(systemctl status apache2 | grep Loaded | grep -c "enabled") -eq 0 ];
then 
  systemctl enable apache2
fi

#Copies log files to a tar file and then copies tar file to S3 bucket
tar -Pcvf /tmp/$myname-httpd-logs-$timestamp.tar /var/log/apache2/*.log

aws s3 \
cp /tmp/${myname}-httpd-logs-${timestamp}.tar \
s3://${s3_bucket}/${myname}-httpd-logs-${timestamp}.tar

#temporary variables
TAR_FILE=/tmp/$myname-httpd-logs-$timestamp.tar
SIZE_IN_BYTE=$(wc -c $TAR_FILE | awk '{print $1}')
SIZE_IN_KB=$(($SIZE_IN_BYTE / 1000))

#data for bookkeeping file
LOG_TYPE="httpd-logs"
DATE_CREATED=$timestamp
TYPE="tar"
SIZE="${SIZE_IN_KB}K"

#Bookkeeping file details
BOOKKEEPING_FILE=/var/www/html/inventory.html
HEADER_DATA="Log Type\tDate Created\tType\tSize"
LOG_DATA="$LOG_TYPE\t$DATE_CREATED\t$TYPE\t$SIZE"

#creates file if not present already
if [ ! -f "$BOOKKEEPING_FILE" ];
then
    echo -e $HEADER_DATA > $BOOKKEEPING_FILE
fi

#appends data into the file
echo -e $LOG_DATA >> $BOOKKEEPING_FILE

#creates CRON job, if not present
CRON_FILE=/etc/cron.d/automation
if [ ! -f "$CRON_FILE" ];
then
    echo "0 0 * * * root /root/Automation_Project/automation.sh" > $CRON_FILE
fi

