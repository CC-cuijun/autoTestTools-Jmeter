#!/bin/sh


export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
shellpath=$(cd $(dirname $0) ; pwd)

#获取自动化测试结果日志dir
resultsLogDir=$1
#获取报告时间
reportTime=`echo $resultsLogDir | cut -d "/" -f4`
#echo $reportTime

#获取测试结果日志文件列表
resultsLogFiles=$(ls  $resultsLogDir|grep -v ".html")
#echo $resultsLogFiles

#强制只生成概要信息
onlySummary=$2
#获取脚本基础配置
source "$shellpath/parms.conf"

if [[ -z $filter ]];then
    filtertmp="'    '"
else
    filtertmp=$filter
fi


#存在错误时单独生成错误报告
reportMode=error

testsummary(){
#生成测试报告html
cat > $resultsLogDir/$reportTime-testSummaryReport.html <<EOF
<!DOCTYPE html> 
<html>
<head>
<meta http-equiv="Content-Type" content="text/html\; charset=utf-8" />
<title>Test Report</title>
</head>
<body>
EOF

for logfile in $resultsLogFiles ;do

#获取请求总数
sample=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|wc -l)
#获取请求成功总数
successNumber=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|grep "true"|wc -l )

#生成概要报告
getTestSummary(){
cat >> $resultsLogDir/$reportTime-testSummaryReport.html << EOF
<h3>$logfile</h3>
<h3>测试结果概要</h3>
<table border="1">
<tr>
<th>测试用例执行条数</th>
<th>测试用例执行成功总数</th>
<th>测试用例执行失败总数</th>
<th>测试用例执行成功率</th>
</tr>
<tr>
<td>$sample</td>
<td>$successNumber</td>
<td>$(($sample-$successNumber))</td>
<td>$(printf "%.2f" `echo "scale=5;($successNumber/$sample)*100"|bc`)%</td>
</tr>
</table>
EOF
}
getTestSummary
done
}


if [[ $onlySummary == s ]];then
   testsummary
   exit 0 
else 

#测试结果中所有用例全部成功，则设置邮件发送规则为不发送
if [ $(cat $resultsLogDir/*.log |grep -v -E "timeStamp,elapsed,label|$filtertmp"|grep "false" |wc -l) == 0  ] ;then 
   echo "用例执行全部成功,默认不发送邮件,set allsuccess=yes."
   sed -i "s/allsuccess=no/allsuccess=yes/g" $shellpath/parms.conf
else
   echo "用例执行存在失败，需要邮件发送,set allsuccess=no"
   sed -i "s/allsuccess=yes/allsuccess=no/g" $shellpath/parms.conf
   falseFlag=false
fi


alltestcase(){
#生成测试报告html
cat > $resultsLogDir/$reportTime-testReport.html <<EOF
<!DOCTYPE html> 
<html>
<head>
<meta http-equiv="Content-Type" content="text/html\; charset=utf-8" />
<title>Test Report</title>
</head>
<body>
EOF

for logfile in $resultsLogFiles ;do

#获取请求总数
sample=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|wc -l)
#获取请求成功总数
successNumber=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|grep "true"|wc -l )

#生成概要报告
getTestSummary(){
cat >> $resultsLogDir/$reportTime-testReport.html << EOF
<h3>$logfile</h3>
<h3>测试结果概要</h3>
<table border="1">
<tr>
<th>测试用例执行条数</th>
<th>测试用例执行成功总数</th>
<th>测试用例执行失败总数</th>
<th>测试用例执行成功率</th>
</tr>
<tr>
<td>$sample</td>
<td>$successNumber</td>
<td>$(($sample-$successNumber))</td>
<td>$(printf "%.2f" `echo "scale=5;($successNumber/$sample)*100"|bc`)%</td>
</tr>
</table>
EOF
}
  
#生成详细报告
getTestCaseDetailList(){

cat >> $resultsLogDir/$reportTime-testReport.html << EOF
<h3>测试Case详情</h3>
<table border="1">
<tr>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $1}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $3}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $4}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $5}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $8}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $9}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $14}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $15}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $16}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $17}'|head -1)</th>
</tr> 
EOF

row=`cat -n $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|awk '{print $1}'`
#echo $row
for i in $row ;do
    echo  "<tr>" >> $resultsLogDir/$reportTime-testReport.html
    timeStamp=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $1}')
    echo  "<td>$timeStamp</td>"  >> $resultsLogDir/$reportTime-testReport.html
    label=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $3}')
    echo  "<td>$label</td>"  >> $resultsLogDir/$reportTime-testReport.html
    responseCode=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $4}')
    echo  "<td>$responseCode</td>"  >> $resultsLogDir/$reportTime-testReport.html
    responseMessage=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $5}')
    echo  "<td>$responseMessage</td>"  >> $resultsLogDir/$reportTime-testReport.html
    success=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $8}')
    echo  "<td>$success</td>"  >> $resultsLogDir/$reportTime-testReport.html
    failureMessage=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $9}')
    echo  "<td>$failureMessage</td>"  >> $resultsLogDir/$reportTime-testReport.html
    URL=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $14}')
    echo  "<td>$URL</td>"  >> $resultsLogDir/$reportTime-testReport.html
    Latency=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $15}')
    echo  "<td>$Latency</td>"  >> $resultsLogDir/$reportTime-testReport.html
    IdleTime=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $16}')
    echo  "<td>$IdleTime</td>"  >> $resultsLogDir/$reportTime-testReport.html
    Connect=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $17}')
    echo  "<td>$Connect</td>"  >> $resultsLogDir/$reportTime-testReport.html
    echo  "</tr>" >> $resultsLogDir/$reportTime-testReport.html
done
echo  "</table>" >> $resultsLogDir/$reportTime-testReport.html
}

    echo "$logfile 生成完整报告。"
    getTestSummary
    getTestCaseDetailList
  
#echo "----------------------------------------------------------------------------------------------------------------------------------------------" >> $resultsLogDir/$reportTime-testReport.html
done

echo  "</body>" >> $resultsLogDir/$reportTime-testReport.html
echo  "</html>" >> $resultsLogDir/$reportTime-testReport.html

}

errortestcase(){
#生成测试报告html
cat > $resultsLogDir/$reportTime-testReport-error.html <<EOF
<!DOCTYPE html> 
<html>
<head>
<meta http-equiv="Content-Type" content="text/html\; charset=utf-8" />
<title>Test Report</title>
</head>
<body>
EOF

for logfile in $resultsLogFiles ;do

#获取请求总数
sample=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|wc -l)
#获取请求成功总数
successNumber=$(cat $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|grep "true"|wc -l )

if [[ $falseFlag == false && $successNumber == $sample ]];then
   continue ;
fi

#生成概要报告
getTestSummary(){
cat >> $resultsLogDir/$reportTime-testReport-error.html << EOF
<h3>$logfile</h3>
<h3>测试结果概要</h3>
<table border="1">
<tr>
<th>测试用例执行条数</th>
<th>测试用例执行成功总数</th>
<th>测试用例执行失败总数</th>
<th>测试用例执行成功率</th>
</tr>
<tr>
<td>$sample</td>
<td>$successNumber</td>
<td>$(($sample-$successNumber))</td>
<td>$(printf "%.2f" `echo "scale=5;($successNumber/$sample)*100"|bc`)%</td>
</tr>
</table>
EOF
}
  
#生成详细报告
getTestCaseDetailList(){
#当只生成测试用例执行失败的报告时，若用例执行全部成功，则不生成详细报告；
cat >> $resultsLogDir/$reportTime-testReport-error.html << EOF
<h3>测试Case详情</h3>
<table border="1">
<tr>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $1}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $3}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $4}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $5}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $8}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $9}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $14}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $15}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $16}'|head -1)</th>
<th>$(cat $resultsLogDir/$logfile| awk -F\, '{print $17}'|head -1)</th>
</tr> 
EOF
row=`cat -n $resultsLogDir/$logfile|grep -v -E "timeStamp,elapsed,label|$filtertmp"|awk '{print $1}'`

for i in $row ;do
  if [[ $(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $8}') = false ]] ; then  
    echo  "<tr>" >> $resultsLogDir/$reportTime-testReport-error.html
    timeStamp=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $1}')
    echo  "<td>$timeStamp</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    label=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $3}')
    echo  "<td>$label</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    responseCode=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $4}')
    echo  "<td>$responseCode</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    responseMessage=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $5}')
    echo  "<td>$responseMessage</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    success=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $8}')
    echo  "<td>$success</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    failureMessage=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $9}')
    echo  "<td>$failureMessage</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    URL=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $14}')
    echo  "<td>$URL</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    Latency=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $15}')
    echo  "<td>$Latency</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    IdleTime=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $16}')
    echo  "<td>$IdleTime</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    Connect=$(sed -n "$i,2p" $resultsLogDir/$logfile|awk -F\, '{print $17}')
    echo  "<td>$Connect</td>"  >> $resultsLogDir/$reportTime-testReport-error.html
    echo  "</tr>" >> $resultsLogDir/$reportTime-testReport-error.html
  else
     continue;
  fi
done
echo  "</table>" >> $resultsLogDir/$reportTime-testReport-error.html
}

    echo "$logfile 生成ERROR报告。"
    getTestSummary
    getTestCaseDetailList
  
#echo "----------------------------------------------------------------------------------------------------------------------------------------------" >> $resultsLogDir/$reportTime-testReport.html
done

echo  "</body>" >> $resultsLogDir/$reportTime-testReport-error.html
echo  "</html>" >> $resultsLogDir/$reportTime-testReport-error.html

}

case $reportMode in 
  all)
    alltestcase
    ;;
  error)
    alltestcase
    if [[ $falseFlag == false ]];then 
      errortestcase
    else
      exit 0 
    fi
    ;;
  *)
   echo "报告支持模式：all、error."
   exit 1
   ;;
esac

fi
