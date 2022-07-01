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
# Step 1. Ingress 설치
##########################################################

# cloud 유형으로 ingress를 설치한다.
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/cloud/deploy.yaml

# kubernetes v1.14.2 부터 ipvs 사용하는데 strict ARP mode를 enable한다.
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system

##########################################################
# Step 2. MetalLB 설치
##########################################################

# S/W Load Balancer인 metallb를 설치한다.
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml

# ingress EXTERNAL-IP에 192.168.1.100 할당
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - 192.168.1.100-192.168.1.200
EOF

##########################################################
# Step 3. Imaginary에 ingress 적용
##########################################################

# Imaginary에 ingress 적용
kubectl apply -f k8s/imaginary-ingress.yml

# EXTERNAL-IP 할당 모니터링
watch kubectl get svc -n ingress-nginx
