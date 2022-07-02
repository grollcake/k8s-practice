#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi


# nfs-server VM에서만 실행한다.
if [ "$HOSTNAME" != "nfs-server" ]; then
    echo "[E] nfs-sever VM에서만 실행 가능합니다"
    exit
fi

##########################################################
# Step 1. nfs server 설치
##########################################################

sudo apt-get -y install nfs-common cifs-utils

