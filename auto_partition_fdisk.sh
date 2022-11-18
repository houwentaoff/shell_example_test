#!/bin/sh - 
#===============================================================================
#
#          FILE: auto_partition.sh
# 
#         USAGE: ./auto_partition.sh 
# 
#   DESCRIPTION: auto_partition.sh -a 可在启动时这样使用
# 
#       OPTIONS: ---
#  REQUIREMENTS: ---
#          BUGS: ---
#         NOTES: ---
#        AUTHOR: Joy 
#  ORGANIZATION: 
#       CREATED: 
#      REVISION:  ---
#===============================================================================
set -o nounset                              # Treat unset variables as an error
GDISK_BIN="fdisk"
#FORMAT_BIN="mke2fs  -i 8192 " #mkfs.ext4
FORMAT_BIN="mkfs.ext4 "
FSCK="e2fsck  -y "
# temp disk for testing gdisk
#$(mktemp) 
TEMP_DISK="/dev/mmcblk0" #"/tmp/aaa" 
# 64 MiB
TEMP_DISK_SIZE=65536
OPT_CLEAR="o"
OPT_NEW="n"
OPT_CHANGE_NAME="c"                   
OPT_CHANGE_TYPE="t"                                                                                
OPT_DELETE="d"
PART_LOCK="/mnt/part_uncomplete_lock"
TEST_PART_TYPE="83"
CUSTOM1_NAME="mmcblk0p2"
CUSTOM2_NAME="mmcblk0p3"
CUSTOM_PARTS="$CUSTOM1_NAME  $CUSTOM2_NAME"
CUSTOM_MOUNTPOINT0="/mnt/data"
CUSTOM_MOUNTPOINT1="/mnt/ccc"
# Pretty print string (Red if FAILED or green if SUCCESS)
# $1: string to pretty print
pretty_print() {                                                                                   
    if [ "$1" == "SUCCESS" ]
    then       
        # green
        color="32"
    else       
        # red  
        color="31"
    fi         
               
    printf "\033[0;${color}m**$1**\033[m $2\n"
}         
# Verify that the partition exist and has the given type/name
# $1: Partition type to verify (ex.: 8300)
# $2: Partition name to verify (ex.: Linux filesystem)
# $3: Text to print                                                                                
verify_part() {
    partition="";
    if [ "$2" == "partmagic" ] ; then
        partition=$($GDISK_BIN -l $TEMP_DISK | grep $2)
    else
        partition=$($GDISK_BIN -l $TEMP_DISK | tail -n 1)
    fi
    echo $partition | grep -q "$1[[:space:]]*$2$"
    ret=$?
    if [ $# -eq 3 ]
    then
        if [ $ret -eq 0 ]              
        then 
            pretty_print "SUCCESS" "$3"
        else 
            pretty_print "FAILED" "$3"
            exit 1                   
        fi   
    else
        return $ret
    fi
}        
verify_tablelimit() {
    partition=$($GDISK_BIN -l $TEMP_DISK)
    echo $partition | grep -q "$1[[:space:]]$2"
         
    if [ $? -eq 0 ]              
    then 
        pretty_print "SUCCESS" "$3"
    else 
        pretty_print "FAILED" "$3"
        exit 1                   
    fi   
}       
create_table() {
    $GDISK_BIN $TEMP_DISK << EOF
$OPT_CLEAR
Y
w
Y
EOF
    ret=$?
    if [ $ret -ne 0 ] ; then
        pretty_print "FAILED" "gdisk return $ret when creating partition table"
        exit 1
    fi      
    verify_part "Code" "Name" "Create new empty GPT table"
    echo ""
}

# $1 part type
# $2 part size
# $3 orgin partition name
# $4 part offset 

create_partition() {
    $GDISK_BIN $TEMP_DISK << EOF
$OPT_NEW
p
${5}
${6}
+${2}
w
EOF
    verify_part "$1" "$3" "Create new partition $3" 
    echo ""
}
# $1 partition name
get_partition_idx() {
    partition_idx=$($GDISK_BIN -l $TEMP_DISK | grep "$1" | awk  '{print $1}')  
    partition_idx=`basename $partition_idx | sed -e 's/mmcblk0p//g'`
    if [ $? -ne 0 ] ; then
        exit 1
    fi
    return $partition_idx
}
# change last partition name
# $1  new name
# $2  partition type
change_partition_name() {       
    partition_idx=$($GDISK_BIN -l $TEMP_DISK | tail -n 1 | awk  '{print $1}')  
    if [ $partition_idx -lt 20 ] ; then
        echo "partition idx err!"
        exit 1
    fi
    if [ $partition_idx -eq 1 ] ; then
        $GDISK_BIN $TEMP_DISK << EOF
$OPT_CHANGE_NAME
$1
w
Y
EOF
    else
        $GDISK_BIN $TEMP_DISK << EOF
$OPT_CHANGE_NAME
$partition_idx
$1
w
Y
EOF
    fi
    verify_part "$2" "$1" "Change partition $partition_idx name --> $1"                                                                      
    echo ""
}
# we do not use it 
change_partition_type() {  
    $GDISK_BIN $TEMP_DISK << EOF
$OPT_CHANGE_TYPE
$TEST_PART_NEWTYPE
w       
Y       
EOF
    verify_part "$TEST_PART_NEWTYPE" "$TEST_PART_NEWNAME" "Change partition 1 type ($TEST_PART_TYPE     -> $TEST_PART_NEWTYPE)"                                                                           
    echo ""
}
change_partition_limit() {
    $GDISK_BIN $TEMP_DISK << EOF
x
s
128
w
Y
EOF
    verify_tablelimit "Partition table holds up to" "128 entries" "Table holds up to 128"                                                 
    echo "" 
}
# $1 partition idx
# $2 partition name
delete_partition() {     
    if [ $1 -eq 0 ] || [ "$1" == "" ] ; then
        echo "del part failed, partition idx err!"
        exit 1
    fi
    $GDISK_BIN $TEMP_DISK << EOF
$OPT_DELETE
$1
w
Y
EOF
    
    #verify_part "Code" "Name" "Delete partition $1"
    finds=$($GDISK_BIN -l $TEMP_DISK | grep -q "$2")
    if [ $? -eq 0 ] ; then
        echo "delete partition $2 failed"
        exit 1
    fi

    echo "" 
}
usage() {                   
    echo "OP hardware watchdog"
    echo "Usage:"           
    echo "  $0 "            
    echo "Description:"    
    echo "    -d.    Delete custom partitions"
    echo "    -a.    Auto partition"
    echo "    -h.    Print the usage"
    exit 0
}

## main
if [ $# -eq 0 ] ; then                         
    usage                                      
fi 
echo -n "check $GDISK_BIN:"
which $GDISK_BIN
if [ $? -ne 0 ] ; then
    echo "$GDISK_BIN is not exist! please check!!!"
    exit 1
fi
# create a file to simulate a real device
if false ; then
    dd if=/dev/zero of=$TEMP_DISK bs=1024 count=$TEMP_DISK_SIZE > /dev/null 2>&1
    if [ -s $TEMP_DISK ] ; then             
        pretty_print "SUCCESS" "Temp disk sucessfully created"
    else             
        pretty_print "FAILED" "Unable to create temp disk !"
        exit 1       
    fi       
fi
do_auto_partition_sys() {
    verify_part "FFEE" "partmagic" "last part" "auto"
    if [ $? -eq 0 ] ; then
        echo "partition is ok!"
        exit 0
    else
        echo "partition is not ok!"
        echo "begin to auto partitioning"
    fi

    change_partition_limit
    if true ; then
        for p in APPSBL_back boot_back userdata_back system_back end
        do
            size="0M"
            pname="Linux filesystem"
            ptype="8300"
            off_size="0M"
            case $p in
                APPSBL_back)
                    off_size="2048M"
                    size="500K"
                    pname="APPSBL"
                    ptype="FF02"
                    ;;
                boot_back)
                    off_size="2049M"
                    size="58.8M" #"1M" #"58.8M"
                    pname="boot"
                    ptype="FF01"
                    ;;
                userdata_back)
                    off_size="2109M"
                    size="384M" #"2M" #"384M"
                    pname="Linux filesystem"
                    ptype="8300"
                    ;;
                system_back)
                    off_size="2500M"
                    size="192M" #"3M" #"192M"
                    pname="Linux filesystem"
                    ptype="8300"
                    ;;
                end)
                    off_size="2700M"
                    size="100K"
                    pname="partmagic"
                    ptype="FFEE"
                    ;;
                *)  echo "undefine size" 
                    exit 1
                    ;;
            esac
            echo ""                                                                                        
            printf "\033[0;34m**Creating partition $p size $size **\033[m\n"
            echo ""           
            create_partition "$ptype" "$size" "$pname" "$off_size"
            if [ "$p" != "end" ] ; then
                change_partition_name  $p $ptype
            fi
        done
    fi
    #
    echo "Automatic partitioning has been completed" 
}

do_auto_partition_user() {
    get_partition_idx "$CUSTOM1_NAME"
    idx=$?
    if [ "$idx" != "" ] && [ $idx -ne 0 ] ; then
        echo "partition is ok!"
        return
    fi
    i=1
    delete_partition 1 "aabbccdd"
    create_partition "83" "30M" "Linux" "0M" 1 "100"
    mkfs.vfat /dev/mmcblk0p1
    echo "format /dev/mmcblk0p1 successed!!"
    #exit 2
    for pp in ${CUSTOM_PARTS} 
    do
        size="0M"
        pname="Linux filesystem"
        ptype="8300"
        off_size="0M"
        case $pp in
            $CUSTOM1_NAME)
                off_size="0M"
                size="1G"
                pname="Linux"
                ptype="83"
                ;;
            $CUSTOM2_NAME)
                off_size="0M"
                size="600M"
                pname="Linux"
                ptype="83"
                ;;
            *)  echo "undefine size" 
                exit 1
                ;;
        esac
        echo ""           
        printf "\033[0;34m**Creating partition $pp size $size **\033[m\n"
        echo ""           
        i=$(( $i + 1 ))
        if [ $i -eq 2 ] ; then
            create_partition "$ptype" "$size" "$pname" "$off_size" "$i" "80000"
        else
            create_partition "$ptype" "$size" "$pname" "$off_size" "$i" "2200000"
            #change_partition_name  $pp $ptype
        fi
    done
    if [ -f $PART_LOCK ] ; then
        pretty_print "ERROR" "Stat err : This is a BUG!!!"
        exit 4
    fi
    mkdir -p `dirname $PART_LOCK`
    touch $PART_LOCK
    sync
    reboot
    echo "Automatic partitioning has been completed, begin to reboot"
    exit 0
}
do_auto_partition() {
    #change_partition_limit
    #do_auto_partition_sys
    do_auto_partition_user
}
do_format(){
    if [ -f $PART_LOCK ] ; then
        for p in ${CUSTOM_PARTS}
        do
            get_partition_idx "$p"
            idx=$?
            if [ "$idx" != "" ] && [ $idx -ne 0 ]  ; then
                echo y | ${FORMAT_BIN}  ${TEMP_DISK}p$idx 
                if [ $? -ne 0 ] ; then
                    pretty_print "FAILED" "mkfs ext4 idx:$idx name:$p"
                    exit 2;
                fi
            fi
        done
        rm -f $PART_LOCK
    fi
}
do_auto_mount(){
    for p in ${CUSTOM_PARTS}
    do
        echo ${p}
        get_partition_idx "$p"
        idx=$?
        if [ "$idx" != "" ] && [ $idx -ne 0 ] ; then
            case $p in  
                $CUSTOM1_NAME)
                    mkdir -p $CUSTOM_MOUNTPOINT0
                    ${FSCK} -y ${TEMP_DISK}p$idx
                    mount ${TEMP_DISK}p$idx  $CUSTOM_MOUNTPOINT0 || ( echo y | ${FORMAT_BIN} ${TEMP_DISK}p$idx && mount ${TEMP_DISK}p$idx  $CUSTOM_MOUNTPOINT0 ) 
                    if [ $? -ne 0 ] ; then
                        pretty_print "FAILED" "mount idx:$idx name:$p"
                    fi
                    ;;
                $CUSTOM2_NAME)
                    mkdir -p $CUSTOM_MOUNTPOINT1
                    ${FSCK} -y ${TEMP_DISK}p$idx
                    mount ${TEMP_DISK}p$idx  $CUSTOM_MOUNTPOINT1 || ( echo y | ${FORMAT_BIN} ${TEMP_DISK}p$idx && mount ${TEMP_DISK}p$idx  $CUSTOM_MOUNTPOINT1 ) 
                    if [ $? -ne 0 ] ; then
                        pretty_print "FAILED" "mount idx:$idx name:$p"
                    fi
                    ;;
                *)  echo "undefine part"
                    exit 3
                    ;;
            esac
        fi
    done
}
do_del_partition_user() {
    for p in $CUSTOM_PARTS
    do
        get_partition_idx "$p"
        idx=$?
        delete_partition $idx $p
    done
}
do_del_partition_sys() {
   verify_part "FFEE" "partmagic" "last part" "auto"
    if [ $? -eq 0 ] ; then
        echo "partition is ok! now we del it"
    else
        echo "partition is not ok! We can not del it!"
        exit 1
    fi

   for p in APPSBL_back boot_back userdata_back system_back end
    do
        if [ "$p" == "end" ] ; then
            p="partmagic"
        fi
        get_partition_idx "$p"
        idx=$?
        delete_partition $idx $p
    done
}
do_del_partition() {
    #do_del_partition_sys
    do_del_partition_user
 }
## main 
while getopts "daht" opt; do
    case $opt in
        a)
            do_auto_partition
            do_format
            do_auto_mount
            ;;
        d)
            echo "not impl"
            #do_del_partition
            ;;
        h)
            usage
            ;;
        t)
            do_auto_mount
            ;;
        *)
            usage
            ;;
    esac
done
