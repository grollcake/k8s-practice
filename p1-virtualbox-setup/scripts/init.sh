#!/bin/bash

# root 또는 sudo로 실행
if (( $EUID != 0 )); then
    echo "[E] root 권한으로 실행해야 합니다."
    exit
fi

##########################################################
# Step 1. 스크립트 파일에 실행 속성 부여
##########################################################

# 스크립트 파일에 실행 속성 부여
find /home/k8s/k8s-practice -name "*.sh" -exec chmod +x {} \;

##########################################################
# Step 2. 기본 패키지 설치
##########################################################
apt update

# NTP(Network Time Protocol) 설정 -- node간 시간 동기화 용도
apt install -y ntp
service ntp restart
ntpq -p

# nfs client
apt -y install nfs-common

# cluser host 등록
sh -c "echo 192.168.0.10  k8s-master >> /etc/hosts"
sh -c "echo 192.168.0.20  k8s-node1 >> /etc/hosts"
sh -c "echo 192.168.0.30  k8s-node2 >> /etc/hosts"
sh -c "echo 192.168.0.40  nfs-server >> /etc/hosts"
