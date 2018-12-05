#!/usr/bin/env bash
sshFree() {
    ips=`awk '{print $1}' ./ip.txt`
    rm -rf /root/authentication.pub /root/.ssh/*
    for ip in ${ips};
    do
        passWD=`awk '/'${ip}'/ {print $3}' ./ip.txt`
        expect <<__EOF
            set timeout -1
            spawn ssh root@${ip}
            expect {
                "yes/no" {send "yes\r";exp_continue}
                "password: " {send "${passWD}\r"}
            }
            expect {
                "*#" {send "rm -rf /root/.ssh/*\r"}
                "*# " {send "rm -rf /root/.ssh/*\r"}
            }
            expect {
                "*#" {send "ssh-keygen -t rsa -C wutong14@huawei.com -b 4096\r"}
                "*# " {send "ssh-keygen -t rsa -C wutong14@huawei.com -b 4096\r"}
            }
            expect {
                "/id_rsa): " {send "\r"; exp_continue}
                "passphrase): " {send "\r"; exp_continue}
                "passphrase again: " {send "\r"}
            }
            expect {
                "*#" { send "exit\r" }
                "*# " { send "exit\r" }
            }
            expect eof
__EOF
        expect <<__EOF
            set timeout -1
            spawn scp root@${ip}:/root/.ssh/id_rsa.pub /root/id_rsa.pub
            expect {
                "yes/no?" {send "yes\r"; exp_continue}
                "password: " {send "${passWD}\r"; exp_continue}
                "password: " {send "${passWD}\r"}
            }
            expect {
                "*#" { send "exit\r" }
                "*# " { send "exit\r" }
            }
            expect eof
__EOF
        cat /root/id_rsa.pub >> /root/authentication.pub
        rm -rf /root/id_rsa.pub
    done

    chmod 644 /root/authentication.pub

    for ip in ${ips};
    do
        passWD=`awk '/'${ip}'/ {print $3}' ./ip.txt`
        expect <<__EOF
            set timeout -1
            spawn scp /root/authentication.pub root@${ip}:/root/.ssh/authorized_keys
            expect {
                "yes/no?" {send "yes\r"; exp_continue}
                "password: " {send "${passWD}\r"}
            }
            expect {
                "*#" { send "exit\r" }
                "*# " { send "exit\r" }
            }
            expect eof
__EOF
    done
    rm -rf /root/authentication.pub
}
changeHostName() {
    ips=`awk '{print $1}' ./ip.txt`
    for ip in ${ips};
    do
        host=`awk '/'${ip}'/ {print $2}' ./ip.txt`
        expect <<__EOF
            spawn ssh root@${ip}
            expect {
                "*#" {send "hostnamectl set-hostname ${host}\r"}
                "*# " {send "hostnamectl set-hostname ${host}\r"}
            }
            expect {
                "*#" { send "exit\r" }
                "*# " { send "exit\r" }
            }
            expect eof
__EOF
    done
}
changePassWD() {
    ips=`awk '{print $1}' ./ip.txt`
    for ip in ${ips};
    do
        expect <<__EOF
            spawn ssh root@${ip}
            expect {
                "*#" {send "passwd\r"}
                "*# " {send "passwd\r"}
            }
            expect {
                "New password: " {send "${1}\r"; exp_continue}
                "Retype new password: " {send "${1}\r"}
            }
            expect {
                "*#" { send "exit\r" }
                "*# " { send "exit\r" }
            }
            expect eof
__EOF
    done
}
if [[ $1 == 'sshFree' ]]; then
    sshFree;
elif [[ $1 == 'changeHostName' ]]; then
    changeHostName;
elif [[ $1 == 'changePass' ]]; then
    changePassWD $2;
else
    echo "please input sshFree changeHostName changePass"
    exit
fi
