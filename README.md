# 自动化测试包使用说明

## 自动化测试包目录介绍

    ├─ opt
        ├── autoTestReports          测试报告文件目录
            ├── xxx1.log                 jmeter原始报告日志
            └── xxx1.log.html            html报告
        └── autoTestTools-Jmeter         测试部署目录
            ├── apache-jmeter-x.x.x      jmeter程序包
            ├── historyReports.sh        测试报告归档脚本 
            ├── htmlReport.sh            html报告生成脚本
            ├── init.sh                  初始化脚本
            ├── parms.conf               脚本基础配置
            ├── sendmail.sh              发送邮件脚本        
            ├── logs                     运行日志文件目录
            ├── testData                 测试数据存放目录
            ├── README.md                自述文件
            ├── run.conf                 jmeter脚本参数配置文件
            ├── run.sh                   测试运行脚本
            └── testscripts              测试脚本存放目录
                ├── xxx1.jmx                 脚本1
                └── xxx2.jmx                 脚本2
		
## 使用方式
##### step1. 下载工具包并按上述 （测试包目录）目录进行部署；
##### step2. 首次部署需执行init.sh脚本，进行测试环境初始化，需要root权限执行
##### step3. 放置测试脚本到testscripts目录；
##### step4. 检查jmeter脚本配置run.conf，配置方式详见配置章节；
##### step5. 更新脚本基础配置文件，配置方式详见配置章节；
##### step6. 存放测试数据（若有）文件到testData目录；
##### step7. 执行测试脚本run.sh
> 说明: 若只跑部分脚本，则将parms.conf配置文件中runlist参数不需要跑的脚本注释掉即可，注释方式：在脚本名前加上#号即可。 如：#xxx1.jmx，代表xxx1.jmx脚本不跑。
jmeter测试脚本中的测试数据路径配置相对路径: ./testData

## 配置

### 配置crontab定时任务自动运行脚本：

> 普通定时任务 eg. 0 0 * * * admin /opt/autoTestTools-Jmeter/run.sh $env

> 每日汇总统计定时任务 eg. 0 0 * * * admin /opt/autoTestTools-Jmeter/run.sh $env t

> 测试报告归档定时任务 eg. 0 2 * * * admin /opt/autoTestTools-Jmeter/historyReports.sh

* crontab配置方法请自行查阅。

### run.conf配置
#### 规范一：
jmeter脚本中的配置统一放置到测试计划**用户定义的变量**对应英文名**User Defined Variables**，各环境使用的变量名称统一，业务接口自有变量在对应线程中自定义，不做统一管理，统一管理的变量为所有业务或大部分业务共有变量。

#### 规范二：
run.conf配置按“环境:key=value”的方式进行配置，key与jmeter统一配置(testplan的**User Defined Variables**)中的变量名称必须一致。

> 如：test:appkey=123xxx123，test代表对应环境，appkey与jmeter统一配置中的变量名称一致，123xxx123代表key(appkey)的值。

### 邮件功能配置方式配置

##### step1. 执行了init.sh脚本后，会安装好mailx客户端；
##### step2. 将邮箱信息写入配置文件parms.conf，参考parms.conf说明：

parms.conf说明：
```
EmailsTEST=sina@sina.com  #配置测试邮件组，多个邮箱用逗号隔开
EmailsPM=sina@gmail.com    #配置项目邮件组，多个邮箱用逗号隔开
sendEmail=true  #邮件发送功能开关
allsuccess=yes  #无需手动配置，程序根据实际情况自动决定是否发送邮件，测试用例全部成功时不发送邮件，统计功能邮件发送不受此配置影响。


#配置发件箱及邮箱服务器等信息
MAILCMD="
env MAILRC=/dev/null LC_CTYPE=zh_CN.utf-8 charset=utf-8 send_charset='us-ascii:iso-8859-1:utf-8' \
  from=sina@sina.com \
  smtp=smtp.sina.com \
  smtp-auth-user=sina \
  smtp-auth-password=sina888 \
  smtp-auth=login mailx
"

#配置filter，多个条件用|隔开即可，如"签名|sign"
filter="签名"

#配置要跑的jmeter脚本清单
runlist="
test.jmx
"
```

## jmeter脚本编写规范
1. 为了减少不必要的资源开销，测试脚本中不需要指定保存测试结果文件，也不需要开启各类监听器;
2. 为了确保测试结果的准确性，每条用例一定要设置正确的断言；
3. 为了确保测试脚本的易维护性，测试脚本应做到用例名称清晰准，注释足够且准确，测试逻辑清晰，脚本整洁有序，删除不必要的测试控件或冗余的逻辑等，确保测试高效，脚本易读易维护；

## 测试报告说明
测试报告路径：/opt/autoTestReports

以执行时间生成一个目录，目录中为当轮运行的各个脚本原始报告日志和html报告文件；

jmeter测试报告原始日志：环境-脚本名-时间戳.log

html测试报告：时间戳-testReport.html

html错误测试报告(用例执行失败时产生)：时间戳-testReport.html

html统计测试报告：时间戳-testSummaryReport.html

## 常见问题
1. 配置不生效
 - 检查run.conf中配置的变量名称是否与jmeter脚本testplan中**用户定义的变量/User Defined Variables**定义的变量名称一致，注意大写小不同也会导致配置不生效；
 - 检查jmeter脚本业务线程中是否有《用户定义的变量/User Defined Variables》覆盖了配置变量；
 - 检查run.conf中的配置是否较jmeter脚本testplan中**用户定义的变量**有遗漏；
 - jmeter接口脚本中是否未引用该名称的变量；
 - mac下sed命令与GNU不一致，在mac下需要安装GNU的sed：  
 > brew install gnu-sed  
 > 在~/.zshrc中配置 alias sed=gsed
2. 测试结果不符合实际
 - 检查jmeter脚本中的断言设置是否合理，是否符合接口或业务定义；
 - 检查筛选条件的配置；
3. 测试脚本启动报错
 - 检查jmeter脚本是否是正确的jmeter脚本；
 - 根据脚本的错误提示进行各项检查；
4. 报告邮件未收到
 - 检查邮箱服务器地址配置是否正确；
 - 检查发件箱用户名密码配置是否正确；
 - 检查收件箱配置是否正确,注意不同的组别；
 - 当轮测试所有脚本执行结果全部成功时不发送邮件；
 - 每日定时任务crontab配置时需要加上参数t，详见crontab配置；
 - 检查邮件发送配置是否打开；
5. 报告不完整
 - 邮件收到的测试报告默认只发送执行失败的用例列表；
 - 统计功能的测试报告只生成每个脚本的概要报告；
