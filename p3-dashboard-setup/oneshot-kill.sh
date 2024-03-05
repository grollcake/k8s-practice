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
# Step 1. 대시보드 설치 및 토큰 출력
##########################################################

# K8S Dashboard 권장 설정에서 Service 유형을 NodePort로 포트는 30443으로 변경해 놓았음
kubectl apply -f k8s/dashboard-recommended.yml

# serviceaccount, ClusterRoleBinding
kubectl apply -f k8s/dashboard-admin-user.yml

# admin-user 로그인 토큰 생성
token=$(kubectl -n kubernetes-dashboard create token admin-user)

# admin-user 토큰을 kube config 파일에 추가
echo "    token: $token" >> ~/.kube/config

echo "-- dashboard admin-user login token -----------------------------------"
echo $token
echo "-----------------------------------------------------------------------"


##########################################################
# Step 2. Lens 접속 용 kube config 출력
##########################################################

# Lens에 추가할 kubeconfig 정보 출력
echo
echo "-- Lens kubeconfig (~/.kube/config) -----------------------------------"
cat ~/.kube/config
echo "-----------------------------------------------------------------------"
