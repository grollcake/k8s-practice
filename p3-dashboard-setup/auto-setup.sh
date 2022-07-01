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

##########################################################
# Step 1. 대시보드 설치 및 토큰 출력
##########################################################

# K8S Dashboard 권장 설정에서 Service 유형을 NodePort로 포트는 30443으로 변경해 놓았음
kubectl apply -f kubernetes-dashboard/k8s-dashboard-recommended.yml

# serviceaccount, ClusterRoleBinding
kubectl apply -f kubernetes-dashboard/k8s-dashboard-admin-user.yml

# admin-user 로그인 토큰 생성
echo "-- dashboard admin-user login token -----------------------------------"
kubectl -n kubernetes-dashboard create token admin-user
echo "-----------------------------------------------------------------------"


##########################################################
# Step 2. apiserver의 인증서에 192.168.1.10 아이피 추가
##########################################################

# apiserver의 기존 인증서 백업
sudo mv /etc/kubernetes/pki/apiserver.crt /etc/kubernetes/pki/apiserver.crt.orig
sudo mv /etc/kubernetes/pki/apiserver.key /etc/kubernetes/pki/apiserver.key.orig

# SAN(Subject Alternative Name)에 192.168.1.10 아이피 추가
sudo kubeadm init phase certs apiserver --apiserver-cert-extra-sans "192.168.0.10,192.168.1.10"

# 인증서에 SAN 아이피 반영 확인
openssl x509 -in /etc/kubernetes/pki/apiserver.crt -text | grep 192.168

# kubectl 명령어가 잘 실행되면 잘 반영된 것
sleep 1
kubectl get all 

# Lens에 추가할 kubeconfig 정보 출력
echo
echo "-- Lens kubeconfig------- ---------------------------------------------"
cat ~/.kube/config
echo "-----------------------------------------------------------------------"
