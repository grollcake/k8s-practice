#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi

##########################################################
# Step 0. 서버 기본 설정
##########################################################
# swap off
swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# NTP(Network Time Protocol) 설정 -- node간 시간 동기화 용도
apt install -y ntp
service ntp restart
ntpq -p

sysctl --system

##########################################################
# Step 1. Docker 설치
##########################################################

# apt가 HTTPS로 리포지터리를 사용하는 것을 허용하기 위한 패키지 설치
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# 도커 공식 GPG 키 추가:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key --keyring /etc/apt/trusted.gpg.d/docker.gpg add -

# 도커 apt 리포지터리 추가:
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# 도커 CE 설치
sudo apt-get update && sudo apt-get install -y containerd.io=1.2.13-2 docker-ce=5:19.03.11~3-0~ubuntu-$(lsb_release -cs) docker-ce-cli=5:19.03.11~3-0~ubuntu-$(lsb_release -cs)

## /etc/docker 생성
sudo mkdir -p /etc/docker

# 도커 데몬 설정
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

# /etc/systemd/system/docker.service.d 생성
sudo mkdir -p /etc/systemd/system/docker.service.d

# 도커 재시작 & 부팅시 실행 설정 (systemd)
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker

# 도커 그룹에 사용자 추가
sudo usermod -aG docker k8s

##########################################################
# Step 2. kubelet kubeadm kubectl 설치
##########################################################

# iptables가 브리지된 트래픽을 보게 하기
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# 구글 클라우드 퍼블릭 키 다운로드
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg

# 쿠버네티스를 설치하기 위해 Kubernetes 저장소 추가
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# kubelet, kubeadm, kubectl를 설치
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# 쿠버네티스를 서비스 등록 및 재시작
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# cri 비활성화를 해제
sudo sed -i '/disabled_plugins/s/^/#/' /etc/containerd/config.toml
sudo systemctl restart containerd

# 쿠버네티스 bash 명령어 자동완성 지원
echo 'source <(kubectl completion bash)' >> ~k8s/.bashrc
echo 'alias k=kubectl' >> ~k8s/.bashrc


##########################################################
# Step 3. k8s Master 설정
##########################################################

# master 노드에서만 실행한다.
if [ "$HOSTNAME" != "k8s-master" ]; then
    echo "All Done. Run manual command 'kubeadm join ...'"
    exit
fi

# master 노드로 설정
sudo kubeadm init --apiserver-advertise-address=192.168.0.10 --pod-network-cidr 10.32.0.0/12

# 모든 사용자가 kube 명령어를 사용할 수 있게 하기 위해 다음을 설정한다.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# CNI weave network add-on install
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')&env.IPALLOC_RANGE=10.32.0.0/12"

# master node 상태 확인
kubectl get nodes -o wide

# kube-system pod 상태 확인
kubectl get pods -n kube-system

# svc 상태 확인
kubectl describe svc
