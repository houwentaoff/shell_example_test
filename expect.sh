#!/bin/bash
passwd='1234' # 该脚本 使用expect命令进行自动化登陆；expect常用于自动化
/usr/bin/expect <<-EOF
set time 10
spawn ssh -l pi pi@192.168.1.102
expect {
"*yes/no" { send "yes\r"; exp_continue }
"*password:" { send "$passwd\r" }
}
expect " $"
send "cd ~/sh\r"
expect " $"
send "echo 1234 > b.txt\r"
expect " $"
send "exit\r"
interact
expect eof
EOF