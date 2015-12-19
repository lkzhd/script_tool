#!/bin/bash

E_SUCCESS=0
E_NOCONF=1

GLOBAL_RETURN=0

function read_conf()
{
        while read line ;do
                peer=${line% *}
                password=${line##* }
                echo -e "Get peer is ${peer}, password is ${password}" 
                /usr/bin/expect <<EOF
                        set timeout 10
                        spawn ssh "$peer" -p 22
                        expect {
                                "(yes/no)" {send "yes\r";exp_continue}
                                "password:" {send "$password\r"}
                        }
                        expect "root@*" {send "hostname\r"}
                        expect "root@*" {send "exit\r"}
                        expect eof
EOF
        done < "$1"
}

if [ ! $# -eq 1 ];then
        echo -e "Need a args as conf file"
else
        if [ ! -f $1 ];then
                echo -e "Need a args as conf file"
                exit $E_NOCONF
        else
                read_conf $1
        fi
fi
exit $E_SUCCESS

