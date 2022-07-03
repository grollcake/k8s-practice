#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi

# master 노드에서만 실행한다.
if [ "$HOSTNAME" != "k8s-master" ]; then
    echo "마스터 노드에서만 실행가능합니다."
    exit
fi

# 현재 스크립트 경로로 변경
cd $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

##########################################################
# Step 1. Persistent Volume 준비
##########################################################
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/nfs-volumes.yaml

##########################################################
# Step 2. wikijs 배포
##########################################################
kubectl apply -f k8s/postgres.yaml
kubectl apply -f k8s/wikijs.yaml
kubectl apply -f k8s/ingress.yaml

watch kubectl get all,pvc,ingress -o wide -n wikijs-app
