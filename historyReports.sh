#!/bin/sh

export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
shellpath=$(dirname "$0")

#testReportDir
reportDir="/opt/autoTestReports"
#设置logDir
logDir="$shellpath/logs"

yesterday=$(date '+%Y%m%d' -d '-1 day')

echo "$(date '+%Y%m%d%H%M%S')_归档昨日测试报告..."
cd $reportDir && tar -czvf $yesterday.tar.gz $yesterday* --remove-files |tee -a $logDir/run.log
echo "归档完毕。"
