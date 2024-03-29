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
# Step 1. todo-app 배포
##########################################################

# k8s deploy
kubectl apply -f k8s/

# 배포가 완료되길 대기
echo "-- Waiting for todo app is ready -----------------------------------"
kubectl wait pod --for=condition=Ready -l app=todo-app -n todo-app --timeout=5m
sleep 1

# 상태 확인
echo "kubectl get all,ep -o wide -n todo-app"
kubectl get all,ep,ingress -o wide -n todo-app

##########################################################
# Step 2. ingress 적용
##########################################################

# ingress 적용: todo.192.168.0.100.sslip.io
kubectl apply -f k8s/todo-app-ingress.yml

# 상태 확인
echo "kubectl get all,ep,ingress -o wide -n todo-app"
kubectl get all,ep,ingress -o wide -n todo-app

# 접속 확인
echo "http://todo.192.168.0.100.sslip.io"
