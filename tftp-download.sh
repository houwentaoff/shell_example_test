#!/bin/ash - 
#===============================================================================
#
#          FILE: 
# 
#         USAGE: 
# 
#   DESCRIPTION: 
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Dr. Fritz Mehner (fgm), mehner.fritz@fh-swf.de
#  ORGANIZATION: FH Südwestfalen, Iserlohn, Germany
#       CREATED: 
#      REVISION:  ---
#===============================================================================

set -o nounset                              # Treat unset variables as an error
tftp_server=192.168.1.5
fail=0
try_cnt=3

SUCCESS=0

cd /mnt/data/
#tftp -b 65536 -g -r test_dir/filelist $tftp_server
tftp -g -r test_dir/filelist $tftp_server
if [ $? -eq 1 ]; then echo "dowloading app failed!"; exit 1;  fi
for i in `seq $try_cnt`
do 
    while read -r line
    do
        echo  "downloading [$line] ..."
        if [ -z $line ]; then continue; fi

        dir=`dirname ${line:8}`
        file=`basename $line`
        mkdir -p $dir
        #tftp -b 65536 -g -r $line $tftp_server -l $dir/$file
        #echo "tftp -g -r $line $tftp_server -l $dir/$file"
        tftp -g -r $line $tftp_server -l $dir/$file
        
        if [ $? -eq 1 ]; then fail=1; echo "dowloading $file failed!"; break;  fi

    done < filelist

    if [ $fail == "0" ]; then SUCCESS=1; break; fi
    fail=0
done

if [ $SUCCESS == "0" ]; then echo "ftp failed;reboot"; reboot;fi

chmod 777 /mnt/data/test_dir
