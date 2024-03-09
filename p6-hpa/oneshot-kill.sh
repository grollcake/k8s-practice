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

# 문제해결
# [증상] kube-system/metrics-server false (missingendpoints) 오류가 나타난다.
# [원인] tls 인증서가 없어서 발생한다.
# [조치] kubelet이 tls 통신을 안해도 되도록 metrics-server의 Deployment에 insecure-tls 옵션을 추가한다.
#       kubectl edit deployment metrics-server -n kube-system
#             - --kubelet-insecure-tls
kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

echo "Applying option '-kubelet-insecure-tls'.. Wait.."

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

