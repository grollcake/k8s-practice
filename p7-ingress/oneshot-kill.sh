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
# Step 1. Ingress 설치
##########################################################

# kubernetes v1.14.2 부터 ipvs 사용하는데 strict ARP mode를 enable한다.
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

# cloud 유형으로 ingress를 설치한다.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/cloud/deploy.yaml

# 설치 완료 대기
echo "-- Waiting for ingress-nginx ready -----------------------------------"
kubectl wait pod --for=condition=Ready -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=5m

# 상태 조회
kubectl get all -n ingress-nginx

##########################################################
# Step 2. MetalLB 설치
##########################################################

# S/W Load Balancer인 metallb를 설치한다.
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

# ingress EXTERNAL-IP에 192.168.1.100 할당
kubectl apply -f k8s/metallb-configmap.yml

##########################################################
# Step 3. dashboard에 ingress 적용
##########################################################

# dashboard에 ingress 적용
kubectl apply -f k8s/dashboard-ingress.yml

##########################################################
# Step 4. Imaginary에 ingress 적용
##########################################################

# Imaginary에 ingress 적용
kubectl apply -f k8s/imaginary-service.yml
kubectl apply -f k8s/imaginary-ingress.yml

# ingress 상태 조회
kubectl get ingress

# EXTERNAL-IP 할당 모니터링
kubectl get svc -n ingress-nginx

# 외부 연결 도메인 확인
kubectl describe ingress

##########################################################
# Step 5. 접속 가이드
##########################################################
echo "https://dashboard.192.168.0.100.sslip.io"
echo "http://imaginary.192.168.0.100.sslip.io"