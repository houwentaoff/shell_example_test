#!/bin/bash - 
#===============================================================================
#
#          FILE: sync.sh
# 
#         USAGE: ./sync.sh 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dr. Fritz Mehner (fgm), mehner.fritz@fh-swf.de
#  ORGANIZATION: FH Südwestfalen, Iserlohn, Germany
#       CREATED: 03/28/2019 22:47
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error


shell 中基本语法与特殊变量
特殊变量
# :存放命令行参数的个数 $# 用于输出
ps:argc 不为0 至少从1开始 
? ：存放最后1条命令的返回码
*或者@ : 存放所有输入的命令行参数；这两个变量在linux中是等价的

特殊字符屏蔽(要将其作为一般字符使用)
"",'',和\ :'' > ""
()有特殊含义，注意它的转义(当成命令解释)
">" bash < rm.sh 意思是rm.sh直接给bash解析? 类似与cat < file???

${} 变量的正规表达式
bash 对 ${} 定义了不少用法。以下是取自线上说明的表列
    ${parameter:-word}    ${parameter:=word}    ${parameter:?word}    ${parameter:+word}    ${parameter:offset}    ${parameter:offset:length}    ${!prefix*}    ${#parameter}    ${parameter#word}    ${parameter##word}    ${parameter%word}    ${parameter%%word}    ${parameter/pattern/string}    ${parameter//pattern/string}

String:为空，表达式为真
-n String: 长度为非0 表达式为真
-z String: 长度为0 表达式为真

整数比较，文件属性判定

<用法详解？？？>

关于参数列表 
$?
$#
$0---$9

if (test expression) then  # 还可if []...   ???test 和 []的区别？？ 可以 if ！ ［! ...］ []中可以用-o 或者 -a （and）
	commands
else
	commands
fi

case语句中，可以使用匹配模式，就是前面说过的元字符匹配模式，而不是正则表达式的匹配(bash不支持case .. [a-z] 但是sh中支持)
case string in
	pattern_1|pattern_2) command1
        ;; #pattern 可以为通配符，甚至是[] 命令
	...
	*) commands;;
esac

for loop_index in arg_list   #省略in和arg_list时候，loop_index依次取$1 $2...
do
	commands
done

while (test expression) 或者 while [ expression ]
do
	commands
done

也可以这样 
while echo "Input your choice"
read choice
do
    ...
done
# arg_list 允许使用通配符
( basename )  剥出指定后缀 。basename filename .a (剥离掉.a的后缀)

#shell 中的括号{ (和[
1.${var} 
2.$(cmd) 
3.()和{} 
4.${var:-string},${var:+string},${var:=string},${var:?string} 
5.$((exp)) 
6.$(var%pattern),$(var%%pattern),$(var#pattern),$(var##pattern)
7.test [] [[]]

PATH=$PATH:~/mydir 是常用的一种
1.Shell 中变量的原形 ${var} 
它是Shell中变量的原形eg: echo ${var}abcd ; mv $filename ${filename}.$tail;这是批量改后缀名的句子
2.命令替换 $(cmd)
先执行cmd命令 再将命令后的标准输出放回到原来的位置，边成了 echo 标准输出
3.一串的命令执行() 和 {} 注意空格和分号
5.POSIX标准的扩展计算:$((exp))
eg:echo $((var++))
7. [[ 是 bash 程序语言的关键字
1>在 [[ 中使用 && 和 || ,[ 中使用 -a 和 -o 表示逻辑与和逻辑或 [中限制长度 如果是字符串如下所示，[[长度比较大暂时理解为不限制[可以用[[进行替换
2>test和[]中可用的比较运算符只有==和!=，两者都是用于字符串比较的，不可用于整数比较，整数比较只能使用-eq, -gt这种形式
3>[ ] 中的长度有一定限制，如[ -z $(cat ./staff_db | grep -w “0000000001”) ]就会提示说[中参数过多,原因在于 staff_db的文件太大么？ 写法不对 应该写成[ -z “$(cat ./staff_db | grep -w “0000000001”)” ] 那上面的会解释成什么呢？会解释成
“`cat ./staff_db | grep -w “0000000001`” 应该用这个而不是用
Makefile中的shell
for d in $(SUBDIRS); do [ -d $$d ] && $(MAKE) -C $$d; done

常用命令
find . -iname "Kconfig" -exec grep -l "WEXT_PRIV" {} \; 参考.vim中的ugrep cgrep

#dd命令写入16进制度 (利用dd 和 echo修改二进制文件指定位置的二进制值) 
echo -e -n "\x60\x61\x62\x63"|dd ibs=1 skip=1 count=2  of=outputfile obs=1 seek=2 conv=notrunc

# rootfs 中rcs S10x固定格式
case "$1" in
    start)
        ;;
    stop)
        ;;
    reload|restart)
        ;;
    *)
        exit 1
esac


