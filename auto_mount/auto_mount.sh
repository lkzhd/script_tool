###################################################
#[author&owner]         lkzhd
#[email]                zhang_duan@outlook.com
###################################################
#!/bin/bash


E_SUCCESS=0 #success
E_NOCONF=2 #no conf file
E_MOUNT=3 #mount failed
E_EARGC=4 #argc num is invalid
E_EARGS=5 #args error
E_MOUNTPOINT=6 #mount point invalid,maybe there are multiple likely dir
E_USER_UNDO=7 #

CURREENT_DIR=`pwd`
CONF_FILE='disk_list'
CONF_FILE_PATH=''

GLOBAL_RETURN=0

function errstr_echo()
{
        case $1 in
                $E_SUCCESS)
                echo "Success"
                ;;

                $E_NOCONF)
                echo "missint conf file"
                ;;

                $E_MOUNT)
                echo "mount failed"
                ;;

                $E_MOUNTPOINT)
                echo "mount point invalid"
                ;;
                
                $E_EARGC)
                echo "argc num is invalid"
                ;;

                $E_EARGS)
                echo "args error"
                ;;

                $E_USER_UNDO)
                echo "user cancel operation"
                ;;

                *)
                echo "unknown error"
        esac
}

function local_mount()
{
        #echo $1 $2
        local return_value=0

        if [ ! $# -eq 2 ];then
                #echo "need 2 args"
                return_value=$E_EARGC
        else
                if [ -d $2 ];then
                        umount $2 &>/dev/null 
                        mount $1 $2 &>/dev/null
                        return_value=$?
:<<eof
                        if [ $? -eq 0 ];then
                                :
                                #echo "mount $line on $mount_point success"
                        else
                                #echo "mount $line on $mount_point failed"
                                return $E_MOUNT
                        fi
eof
                else
                        #echo "missing mount point"
                        return_value=$E_MOUNTPOINT
                fi
        fi
        return $return_value
}

function read_conf_and_mount()
{
        local conf_path=$1
        local local_return=0

        #echo $conf_path
        if [ ! -f $conf_path ];then
                return $E_NOCONF
        else
                while read line;do
                        #echo $line
                        mkfs.xfs -f $line &>/dev/null 
                        expect_num=1
                        num=`find /mnt/ -name "*${line##*/}*" -type d -maxdepth 1|wc -l`
                        if [ $num -eq $expect_num ];then
                                mount_point=`find /mnt/ -name "*${line##*/}*" -type d -maxdepth 1`
                                local_mount $line $mount_point
                                local_return=$?

:<<eof
                                if [ $local_return -eq 0 ];then
                                        echo "mount $line on $mount_point success"
                                else
                                        echo "mount $line on $mount_point failed"
                                fi
eof

                        elif [ $num -eq 0 ];then
                                echo "mount point is not exist, so create"
                                mkdir -p "/mnt/disk_${line##*/}" &>/dev/null
                                local_return=$?
                                if [ $local_return -eq 0 ];then
                                        :
                                else
                                        break
                                        #echo "create mount point failed, $line mount failed"
                                fi
                                
                                mount_point=`find /mnt/ -name "*${line##*/}*" -type d -maxdepth 1`
                                local_mount $line $mount_point
                                local_return=$?
                                
:<<eof
                                if [ $local_return -eq 0 ];then
                                        echo "mount $line on $mount_point success"
                                else
                                        echo "mount $line on $mount_point failed"
                                fi
eof

                        else
:<<eof
                                echo "mount point ambiguity, have $num likely dir:"
                                for s in `find /mnt/ -name "*${line##*/}*" -type d -maxdepth 1`
                                do
                                        echo $s
                                done
eof
                                local_return=$E_MOUNTPOINT
                        fi
                done < "$conf_path"
        fi
        return $local_return
}

function input_handler()
{
        local return_value=0
        #echo "$1"
        echo -e "NOTICE:Select \033[31m$1\033[0m as config file?"
        echo -e "File content:"
        while read line;do
                echo -e "\t$line"
        done < "$1"

        echo -e "\033[31minput [yes/no]: \033[0m"

        read user_input
        case $user_input in
                "yes"|"y"|"YES"|"Y")
                return_value=$E_SUCCESS
                ;;

                *)
                return_value=$E_USER_UNDO
        esac
        return $return_value
}

if [ $# -eq 1 ];then
        CONF_FILE_PATH=$1
        #echo ${CONF_FILE_PATH:0:2}
        if [ ${CONF_FILE_PATH:0:2} == "/*" ];then
                #echo "absolute path"
                :
        else
                #echo "relative path"
                CONF_FILE_PATH="${CURREENT_DIR}/${CONF_FILE_PATH}"
                #echo "$CONF_FILE_PATH"
        fi
else
        CONF_FILE_PATH="${CURREENT_DIR}/${CONF_FILE}"
fi

input_handler $CONF_FILE_PATH
GLOBAL_RETURN=$?
if [ $GLOBAL_RETURN -eq 0 ];then
        if [ -f $CONF_FILE_PATH ];then
                read_conf_and_mount $CONF_FILE_PATH
                GLOBAL_RETURN=$?
        else
                #echo "there is not conf_file"
                GLOBAL_RETURN=$E_NOCONF
        fi
else
        :
fi

#echo $GLOBAL_RETURN
errstr_echo $GLOBAL_RETURN
exit $GLOBAL_RETURN

