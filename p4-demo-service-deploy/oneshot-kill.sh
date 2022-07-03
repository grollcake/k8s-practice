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
# Step 1. imaginary 배포
##########################################################

# imaginary pod 한개 배포
kubectl apply -f k8s/imaginary-deployment.yml

# imaginary NodePort 서비스 배포 (Port: 30000)
kubectl apply -f k8s/imaginary-service.yml


# 배포가 완료되길 대기
echo "-- Waiting for service ready -----------------------------------"
kubectl wait pod --for=condition=Ready -l app=imaginary
sleep 1

# 헬스체크 API 호출
echo 'curl -H "API-Key: awesome-k8s" 127.0.0.1:30000/health'
curl -H "API-Key: awesome-k8s" 127.0.0.1:30000/health
