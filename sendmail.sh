#!/bin/sh


export PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin:/root/bin
shellpath=$(cd $(dirname $0) ; pwd)


#获取脚本基础配置
source "$shellpath/parms.conf"

send(){
       echo "Email sending..."
       echo -e "测试报告已生成，详见附件！\n \nfrom:autoTester \n----------------------------------------------------------------------------- \n任何使用问题请联系作者。\nQQ:312526353 \nEmail:312526353@qq.com.com"|$MAILCMD -s "autoTestReport" -a $attachment $EmailsTEST
}

sendTJ(){
       echo "统计报告生成。"
       echo "Email sending..."
       echo -e "今日自动化测试情况汇总，详见附件！\n \nfrom:autoTester \n----------------------------------------------------------------------------- \n任何使用问题请联系作者。\nQQ:312526353 \nEmail:312526353@qq.com"|$MAILCMD -s "autoTestReport" -a $attachment $EmailsPM
}

Usage(){
    echo "usage:$0 -a 附件"
}


while [ -n "$1" ]
do
    case "$1" in
        -h|help|--help) 
          Usage
          ;;
        -a) 
          attachment="$2"
          shift 
          ;;
        -s)
          if [[ $allsuccess == no ]];then
              send
          else
              exit 1
          fi 
          shift
          ;;
        -fs)
          sendTJ
          shift
          ;;
        -ns)
          echo "参数-ns生效，不发送邮件。" 
          shift
          ;;
        --)
          shift
          break
          ;;
        *) 
          echo "$1 is not an option"
          ;;
    esac
    shift
done


