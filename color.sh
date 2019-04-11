#!/bin/bash                             
############################################################
########Joy Hou                        
########显示shell的色彩组合             
###用 \033[attr;fore;backm    \033[0m   
###如attr为5则会闪烁                    
#在控制终端里面会闪烁，我的伪终端不会显示闪烁。ssh远程连接上会显示闪烁
############################################################
for attr in 0 1 4 5 7 ; do              
    echo "----------------------------------------------------------------" 
    printf "[attr: %s;Foreground;Background -] \n" $attr                        
    for fore in 30 31 32 33 34 35 36 37; do 
        for back in 40 41 42 43 44 45 46 47; do 
            printf '\033[%s;%s;%sm %02s;%02s ' $attr $fore $back $fore $back
            printf '\033[0m'            
        done                            
        printf '\n'                     
    done                                
    printf '\033[0m'                    
done
