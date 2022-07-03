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

# nfs 서버 모듈 설치 (아무것도 묻지않고 기본값으로 설치하도록 한다)
export DEBIAN_FRONTEND=noninteractive
apt install -y nfs-kernel-server nfs-common

# 로그를 저장할 2개의 디렉토리 생성
mkdir -p /var/nfs_storage
chmod 777 /var/nfs_storage
runuser -l k8s -c 'mkdir -p /var/nfs_storage/apache-log'
runuser -l k8s -c 'mkdir -p /var/nfs_storage/nginx-log'


# 샘플 파일 생성
cat <<EOF | tee /var/nfs_storage/hello.txt
Hello
EOF

cat <<EOF | tee /etc/exports
/var/nfs_storage 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF

systemctl restart nfs-server

# nfs 공유 상태 보기
exportfs
