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
# Step 1. Metric Server 설치
##########################################################

# metric server 설치
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 작동 확인: metrics-server가 True가 될 때까지 대기한다.
echo "----------------------------------------------------------------"
echo "metrics-server의 Deployment에 insecure-tls 옵션을 추가해야 한다."
echo "다른 터미널에서 아래의 명령을 실행하세요"
echo ">  kubectl edit deployment metrics-server -n kube-system"
echo ">      - --kubelet-insecure-tls <= 추가"
echo "완료되길 대기 중..."

while kubectl get apiservices | grep metrics | grep False > /dev/null;
do
    sleep 1
done

# metric server 적용 여부 확인
kubectl top nodes
kubectl top pods

##########################################################
# Step 2. imaginary hpa 적용
##########################################################

# imaginary HPA 한개 배포
kubectl apply -f k8s/imaginary-hpa.yml

# hpa 상태 체크
kubectl get hpa

