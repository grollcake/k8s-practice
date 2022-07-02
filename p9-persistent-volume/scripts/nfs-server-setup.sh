#!/bin/bash

# root 또는 sudo로 실행
if (( $EUID != 0 )); then
    echo "[E] root 권한으로 실행해야 합니다."
    exit
fi

# nfs-server VM에서만 실행한다.
if [ "$HOSTNAME" != "nfs-server" ]; then
    echo "[E] nfs-sever VM에서만 실행 가능합니다"
    exit
fi

# 현재 스크립트 경로로 변경
cd $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

##########################################################
# Step 1. nfs server 설치
##########################################################

export DEBIAN_FRONTEND=noninteractive

apt install -y nfs-kernel-server portmap

mkdir -p /var/nfs_storage
chmod 777 /var/nfs_storage

cat <<EOF | tee /etc/exports
/var/nfs_storage 192.168.1.0/24(rw)
EOF

systemctl restart nfs-server

exportfs

