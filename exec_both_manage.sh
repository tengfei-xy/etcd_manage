#!/bin/bash

etcd_config_file=$(sudo systemctl cat etcd | grep "^EnvironmentFile.*" -o | awk -F '-' '{print $2}')
log_file="$(dirname "${etcd_config_file}")/systemd_manage.log"

etcd_host1=$(grep "ETCD_INITIAL_CLUSTER=.*" "${etcd_config_file}"  -o | cut -c 22- | awk -F ',' '{print $1}'  | awk -F '=' '{print $1}')
etcd_host2=$(grep "ETCD_INITIAL_CLUSTER=.*" "${etcd_config_file}"  -o | cut -c 22- | awk -F ',' '{print $2}'  | awk -F '=' '{print $1}')
etcd_host3=$(grep "ETCD_INITIAL_CLUSTER=.*" "${etcd_config_file}"  -o | cut -c 22- | awk -F ',' '{print $3}'  | awk -F '=' '{print $1}')
# 主机列表
hosts=("$etcd_host1" "$etcd_host2" "$etcd_host3")

action=$1
# ssh的远程用户
user=tengfei

function ping_test(){
    for host in "${hosts[@]}"; do
        # 忽略本机名
        if [ "$host" == "$(hostname)" ] || [ "$host" == "$(hostname -s)" ] || [ "$host" == "$(hostname -a)" ];then
            continue
        fi

        ping "$host" -c 2 > /dev/null 2>&1
        ret=$?
        if [ "$ret" -ne 0 ]; then
            echo "$(date +%F\ %T) $host failed" | sudo tee -a "$log_file"
            return
        fi
    done
    echo "ok"
}


function exec(){
    # 循环遍历主机列表并启动服务
    for host in "${hosts[@]}"; do
         ssh "${user}"@"$host" "sudo systemctl ${action} etcd"  &
        # echo "$(date +%F\ %T) $host etcd  ${action}." | sudo tee -a  "$log_file"
    done
    sleep 2
    status
    exit 0

}
function status(){
    local state
    for host in "${hosts[@]}"; do
        state=$(ssh "${user}"@"$host" "sudo systemctl show etcd --property ActiveState | awk -F '=' '{print \$2}'")
        echo "$(date +%F\ %T) $host etcd is ${state}."
    done
    exit 0
}
function check(){
    echo "------------------------" | sudo tee -a  "$log_file"
    sudo systemctl cat etcd >/dev/null 2>&1 || {
        echo "etcd no running?"
        exit 1
    }

    if [ "$action" != "start" ] && [ "$action" != "stop" ] && [ "$action" != "status" ];then
        echo "usage: $(basename "$0") [start] | [stop] | [status]"
        exit 1
    fi
}
function main(){

    while test  "$(ping_test)" == "ok"
    do
        break
    done

    # echo "$(date +%F\ %T) all host up" | sudo tee -a  "$log_file"
    if [ "$action" == "start" ] || [ "$action" == "stop" ];then
        exec
    fi
    if [ "$action" == "status" ] ;then
        status
    fi
}
check
main