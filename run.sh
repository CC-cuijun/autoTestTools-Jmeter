#!/bin/sh
#Create by cuijun 2017-5-26
#Update 2017-05-27 Add usage
#修改配置文件读取方式 2017-06-01 by cuijun
#增加环境参数判断  2017-06-05 by cuijun
#修改脚本读取方式 2019-12-17 by cuijun
#优化配置方式 2019-12-17 by cuijun
#增加html报告 2019-12-17 by cuijun
#bugfix: 修复配置文件读取的bug；修复html测试报告字段错位  2019-12-19 by cuijun
#bugfix: 修复脚本列表获取错误  2020-01-07 by cuijun
#2020-01-14 by cuijun
##优化html测试报告，并可定制化测试报告内容，默认只展示执行失败的用例；
##优化测试报告目录及部署路径，统一部署，统一输入输出；
##bugfix：修复run.conf参数匹配不上替换错误问题
#2020-01-15 by cuijjun 
##增加运行日志 
##增加强制邮件发送功能
##增加每日统计只发送概要报告功能
##优化html生成方式



export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
shellpath=$(cd $(dirname $0) ; pwd)

#设置环境参数
env=$1
#设置统计开关，开启后只生成统计信息,并强制发送邮件。
summaryType=$2

#jmeterDir
Jmeter="$shellpath/apache-jmeter-5.1.1/bin/jmeter"
#testReportDir
reportDir="/opt/autoTestReports"
#testscriptsDir
testscriptsDir="$shellpath/testscripts"
#设置logDir
logDir="$shellpath/logs"

#获取脚本基础配置
source $shellpath/parms.conf


echo "$(date +%Y%m%d%H%M%S) autoTest starting..." |tee -a $logDir/run.log

#获取jmeter脚本参数
get_config(){

conf=$(cat "$shellpath/run.conf"|sed -n '/^[^#].*/p'|sed -e s/[[:space:]]//g -e /^$/d|grep "^$env:")
#echo $conf

if [[ -z $conf ]];then
    echo "未配置该环境" |tee -a $logDir/run.log
    exit 1
fi
#echo "$conf"
echo "-----------Reading configuration file... "|tee -a $logDir/run.log
for s in $conf

do
#read config
name=`echo $s | cut -d= -f1| cut -d: -f2`
#echo $name
value=`echo $s | cut -d= -f2`
#echo $value
#获取testplan用户变量配置最大行数
configMaxrows=`cat $testscriptsDir/$script |grep -n -E "^      </elementProp>"|awk -F\: '{print $1}'`

#get target_name's number
targetnamenum=`grep -wn "<stringProp name=\"Argument.name\">$name" $testscriptsDir/$script | head -1 | cut -d ":" -f 1`
#echo $targetnamenum
if [ -z $targetnamenum ] ;then
   echo "$s 配置未找到"
   continue;
elif [[ $targetnamenum -gt $configMaxrows ]] ;then
#   echo "$targetnamenum > $configMaxrows"
   continue;
fi
targetvaluenum=`awk "BEGIN{a=$targetnamenum;b="1";c=(a+b);print c}"`
#echo $targetvaluenum
#modify value
sed -i "$targetvaluenum c \ \ \ \ \ \ \ \ \ \ \ \ <stringProp name=\"Argument.value\">$value</stringProp>" $testscriptsDir/$script

done
echo "----------Read the configuration file complete!"|tee -a $logDir/run.log

}


run(){

#get timestamp
timestamp=$(date +%Y%m%d%H%M%S)

for script in `echo "$runlist"|grep -vE "^#"` ; do
    get_config
#run_testscript
    $Jmeter -n -t $testscriptsDir/$script -l "$reportDir/$timestamp/$env-$script.log"  |tee -a $logDir/run.log
  done
./htmlReport.sh $reportDir/$timestamp |tee -a $logDir/run.log \
&& ./sendmail.sh -a $reportDir/$timestamp/$timestamp-testReport-error.html -s  |tee -a $logDir/run.log
echo "$(date +%Y%m%d%H%M%S) finished..." |tee -a $logDir/run.log
}

runNomail(){

#get timestamp
timestamp=$(date +%Y%m%d%H%M%S)

for script in `echo "$runlist"|grep -vE "^#"` ; do
    get_config
#run_testscript
    $Jmeter -n -t $testscriptsDir/$script -l "$reportDir/$timestamp/$env-$script.log"  |tee -a $logDir/run.log
  done
./htmlReport.sh $reportDir/$timestamp |tee -a $logDir/run.log 
echo "sendEmail!=true,不发送邮件"
#&& ./sendmail.sh -a $reportDir/$timestamp/$timestamp-testReport-error.html -s  |tee -a $logDir/run.log
echo "$(date +%Y%m%d%H%M%S) finished..." |tee -a $logDir/run.log
}


runSummary(){

#get timestamp
timestamp=$(date +%Y%m%d%H%M%S)

for script in `echo "$runlist"|grep -vE "^#"` ; do
    get_config
#run_testscript
    $Jmeter -n -t $testscriptsDir/$script -l "$reportDir/$timestamp/$env-$script.log" |tee -a $logDir/run.log
  done 
./htmlReport.sh $reportDir/$timestamp s |tee -a $logDir/run.log \
&& ./sendmail.sh -a $reportDir/$timestamp/$timestamp-testSummaryReport.html -fs  |tee -a $logDir/run.log
echo "$(date +%Y%m%d%H%M%S) finished..." |tee -a $logDir/run.log
}

runSummaryNomail(){

#get timestamp
timestamp=$(date +%Y%m%d%H%M%S)

for script in `echo "$runlist"|grep -vE "^#"` ; do
    get_config
#run_testscript
    $Jmeter -n -t $testscriptsDir/$script -l "$reportDir/$timestamp/$env-$script.log" |tee -a $logDir/run.log
  done
./htmlReport.sh $reportDir/$timestamp s |tee -a $logDir/run.log 
echo "sendEmail!=true,不发送邮件"
#&& ./sendmail.sh -a $reportDir/$timestamp/$timestamp-testSummaryReport.html -fs  |tee -a $logDir/run.log
echo "$(date +%Y%m%d%H%M%S) finished..." |tee -a $logDir/run.log
}


Usage(){
    echo "usage:$0 env"
}

Help(){
    echo "usage:$0 env"
    echo "详细使用方法见README.md"
}

case "$env" in
-h|--help|help)
    Help
    exit 1
    ;;
esac

if [[ -n $env && -z $summaryType ]];then
   if [[ $sendEmail == true ]];then 
     run
   else
     runNomail
   fi   
elif [[ -n $env && $summaryType = t ]];then
   if [[ $sendEmail == true ]]; then
    runSummary 
   else
    runSummaryNomail
   fi
else
   Usage
   exit 1
fi

