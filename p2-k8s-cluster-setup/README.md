# P2-k8s cluster setup

모든 노드에 공통으로 docker, containerd, kubectl, kubeadm, kubelet을 설치한다.

Master 노드에는 `kubeadm init`으로 마스터 역할을 부여하고, 워커 노드는 `kubeadm join`으로 마스터 노드에 참여한다.



### 0. 설치 패키지 & 버전

```
docker-ce 5:25.0.3-1~ubuntu.20.04~focal
docker-ce-cli 5:25.0.3-1~ubuntu.20.04~focal
containerd.io 1.6.28-1
kubeadm 1.28.7-1.1
kubectl 1.28.7-1.1
kubelet 1.28.7-1.1
kubernetes-cni 1.2.0-2.1
```



### 1. 준비 절차

```bash
# 패키지 업데이트
sudo apt update && sudo apt upgrade

# swap off -- k8s 권고 사항
sudo swapoff -a
sudo sed -i '/swap/s/^/#/' /etc/fstab
sudo sysctl --system  # 커널 파라미터를 적용하고 재로드

# NTP(Network Time Protocol) 설정 -- node간 시간 동기화 용도
sudo apt install ntp
sudo service ntp restart
sudo ntpq -p

# iptables가 브리지된 트래픽을 보게 하기 -- k8s 권고 사항
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

# iptables가 브리지된 트래픽을 보게 하기 -- k8s 권고 사항
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# 현재 설정 보기
sudo sysctl --system
```



### 2. k8s 런타임으로 docker 설치

```bash
# apt가 HTTPS로 리포지터리를 사용하는 것을 허용하기 위한 패키지 설치
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common gnupg2

# 도커 공식 GPG 키 추가:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# 도커 apt 리포지터리 추가:
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 도커 CE 설치
sudo apt-get install -y containerd.io=1.6.28-1 \
     docker-ce=5:25.0.3-1~ubuntu.20.04~$(lsb_release -cs) \
     docker-ce-cli=5:25.0.3-1~ubuntu.20.04~$(lsb_release -cs)

## /etc/docker 생성
sudo mkdir /etc/docker

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
sudo usermod -aG docker $USER
```



### 3. k8s 설치

Master, Worker 모든 노드에 설치한다.

```bash
# 구글 클라우드 퍼블릭 키 다운로드
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg

# 쿠버네티스를 설치하기 위해 Kubernetes 저장소 추가
echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# kubelet, kubeadm, kubectl를 설치
apt-get update
apt-get install -y kubelet=1.28.7-1.1 kubeadm=1.28.7-1.1 kubectl=1.28.7-1.1
apt-mark hold kubelet kubeadm kubectl

# 쿠버네티스를 서비스 등록 및 재시작
systemctl daemon-reload
systemctl restart kubelet

# (문제해결) Ubuntu 20.04 / containerd.io 1.3.7 이상에서는 config.toml 파일이 존재하면 kubeadm init 할 때 오류가 발생한다.
# 오류: "container is not runtime runnig unknown service runtime.v1.RuntimeService error"
sudo rm /etc/containerd/config.toml
sudo systemctl restart containerd

```



### 4. master 설정

pod-network-cidr을 Weave.net의 IPALLOC_RANGE에도 동일하게 적용하여 노드/파드간 통신이 잘 되도록 한다.

```bash
sudo kubeadm init --apiserver-advertise-address=192.168.0.10 --pod-network-cidr 10.32.0.0/12

# Weave.net CNI 설치
sudo kubectl apply -f "https://github.com/weaveworks/weave/releases/download/v2.8.1/weave-daemonset-k8s.yaml"
```
위 명령어 실행의 결과로 나오는 명령어를 node 서버에서 실행하면 자동으로 node로 합류하게 된다.



k8s 계정으로 kubectl 명령어 사용가능하게 설정

```bash
# 현재 kubectl 명령어를 사용할 수 있게 하기 위해 다음을 설정한다.
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```



### 5. node 설정

`kubeadm init` 명령의 결과로 나온 `kubeadm join ...` 명령어를 실행한다.



### 6. 결과 확인

마스터에서 노드 상태를 조회해본다.

```
kubectl get nodes -o wide
```



### 문제 해결 (updated: '24.03월 현재 더 이상 발생하지 않는다)

##### (1) container runtime is not running

> `kubeadm init` 실행할 때 `[ERROR CRI]: container runtime is not running` 오류 발생

https://hungc.tistory.com/186

##### (2) weave-net CrashLoopBackOff

pod 상태를 조회해보면 weave-net에 CrashLoopBackOff가 발생한다.

>kubectl get pods -n kube-system
>
>weave-net-8nddv                      1/2     CrashLoopBackOff    51 (61s ago)    22h
>weave-net-dt6zl                      1/2     CrashLoopBackOff    113 (13m ago)   22h

kube-proxy에서 사용하는 CIDR과 API Server에서 사용하는 CIDR이 달라서 발생하는 것처럼 보인다. 확실치는 않다.

Service에서 사용하는 IP를 확인해보면 10.96.0.0 대역인 것을 알수 있다.

```bash
newgw2022@k8s-master:~$ kubectl describe svc kubernetes
Name:              kubernetes
Namespace:         default
Labels:            component=apiserver
                   provider=kubernetes
Annotations:       <none>
Selector:          <none>
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.96.0.1
IPs:               10.96.0.1
Port:              https  443/TCP
TargetPort:        6443/TCP
Endpoints:         192.168.0.10:6443
Session Affinity:  None
Events:            <none>
```

Worker 노드에 할당한 내부 아이피(192.168.0.x)와 NIC를 확인한다. eth1에 192.168.0.20을 사용하고 있다.

```
newgw2022@k8s-node1:~$ ip -4 -o addr
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
2: eth0    inet 10.0.2.15/24 brd 10.0.2.255 scope global dynamic eth0\       valid_lft 85453sec preferred_lft 85453sec
3: eth1    inet 192.168.0.20/24 brd 192.168.0.255 scope global eth1\       valid_lft forever preferred_lft forever
4: docker0    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0\       valid_lft forever preferred_lft forever
7: weave    inet 10.40.0.0/12 brd 10.47.255.255 scope global weave\       valid_lft forever preferred_lft forever
```

Worker 노드에서 ip route를 추가해주면 해결된다.

```bash
sudo ip route add 10.96.0.0/16 dev eth1 src 192.168.0.20
```

Worker 노드 2번에도 동일 작업을 실행한다.

```bash
sudo ip route add 10.96.0.0/16 dev eth1 src 192.168.0.30
```

##### (3) 워커노드에서 join 시 apiserver의 CA token이 유효하지 않다는 오류 발생

```
error execution phase preflight: couldn't validate the identity of the API Server: invalid discovery token CA certificate hash: invalid hash "sha256:9a225953969f9164d08a9505c6f323e316c842656feeee9fca2715a6f8e7e9a", expected a 32 byte SHA-256 hash, found 31 bytes
```

마스터노드에서 토큰을 재생성하면 해결된다. 재생성하면서 워커노드에서 실행할 join 명령어도 같이 출력한다.

```
kubeadm token list
kubeadm delete token ....
kubeadm token create --print-join-command
```



### 참고링크

Kubernetes Cluster 설치 및 구축 (Ubuntu 18.04) https://velog.io/@dry8r3ad/Kubernetes-Cluster-Installation