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
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab

sudo sysctl --system  # 커널 파라미터를 적용하고 재로드

##########################################################
# Step 1. Docker 설치
##########################################################

# apt가 HTTPS로 리포지터리를 사용하는 것을 허용하기 위한 패키지 설치
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# 도커 공식 GPG 키 추가:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 도커 apt 리포지터리 추가:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 도커 CE 설치
sudo apt-get update 
#sudo apt install -y docker-ce docker-ce-cli containerd.io
sudo apt-get install -y containerd.io=1.6.28-1 \
     docker-ce=5:25.0.3-1~ubuntu.20.04~$(lsb_release -cs) \
     docker-ce-cli=5:25.0.3-1~ubuntu.20.04~$(lsb_release -cs)

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
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# 구글 클라우드 퍼블릭 키 다운로드
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

# 쿠버네티스를 설치하기 위해 Kubernetes 저장소 추가
echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# kubelet, kubeadm, kubectl를 설치
sudo apt-get update
apt-get install -y kubelet=1.28.7-1.1 kubeadm=1.28.7-1.1 kubectl=1.28.7-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# 쿠버네티스를 서비스 등록 및 재시작
sudo systemctl daemon-reload
sudo systemctl restart kubelet

# (문제해결) Ubuntu 20.04 / containerd.io 1.3.7 이상에서는 config.toml 파일이 존재하면 kubeadm init 할 때 오류가 발생한다.
# 오류: "container is not runtime runnig unknown service runtime.v1.RuntimeService error"
sudo rm /etc/containerd/config.toml
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
kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml"

# master node 상태 확인
kubectl get nodes -o wide

# kube-system pod 상태 확인
kubectl get pods -n kube-system

# svc 상태 확인
kubectl describe svc
