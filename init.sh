#! /bin/sh

# 安装测试所需软件
# 初始化测试服务器

yum -y install mailx
yum -y install bc;

chmod 744 *.sh

mkdir /opt/autoTestReports

