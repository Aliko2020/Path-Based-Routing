#!/bin/bash
yum update -y
yum install -y httpd
# start httpd daemon
systemctl start httpd
# set http daemon to run at boot time
systemctl enable httpd
mkdir /var/www/html/blue
# populate /blue directory of server with web page
cd /var/www/html/blue
aws s3 cp s3://arr-bucket-123456/hw-blue.css ./
aws s3 cp s3://arr-bucket-123456/hw-blue-py.css ./
aws s3 cp s3://arr-bucket-123456/python.png ./
aws s3 cp s3://arr-bucket-123456/apache.svg ./
aws s3 cp s3://arr-bucket-123456/blue-index.html ./index.html
# populate root of web server with web page (replaces apache default page)
cd /var/www/html
aws s3 cp s3://arr-bucket-123456/hw-blue.css ./
aws s3 cp s3://arr-bucket-123456/hw-blue-py.css ./
aws s3 cp s3://arr-bucket-123456/python.png ./
aws s3 cp s3://arr-bucket-123456/apache.svg ./
aws s3 cp s3://arr-bucket-123456/blue-root-index.html ./index.html
# optional restart of httpd daemon
systemctl restart httpd