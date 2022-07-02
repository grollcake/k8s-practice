#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi

##########################################################
# Step 1. nfs server 설치
##########################################################

sudo apt-get -y install nfs-common cifs-utils

sudo mount -t nfs 192.168.1.40:/var/nfs_storage /home/k8s/nfs-share