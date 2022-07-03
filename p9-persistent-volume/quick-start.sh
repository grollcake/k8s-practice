#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi

# master 노드에서만 실행한다.
if [ "$HOSTNAME" != "k8s-master" ]; then
    echo "All Done. Run manual command 'kubeadm join ...'"
    exit
fi

# 현재 스크립트 경로로 변경
cd $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

##########################################################
# Step 1. Apache에 PV 할당하여 생성
##########################################################

# pv, pvc, apache pod 생성 
kubectl apply -f k8s/apache-with-pv.yml

# 상태 조회
kubectl get all,pv,pvc -o wide -n apache

##########################################################
# Step 2. nginx에 PV와 subpath를 생성
##########################################################

# pv, pvc, apache pod 생성 
kubectl apply -f k8s/nginx-with-pv-subpath.yml

# 상태 조회
kubectl get all,pv,pvc -o wide -n ngix
