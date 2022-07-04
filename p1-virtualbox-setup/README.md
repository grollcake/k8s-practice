# P1-Vagrant를 이용한 VM 생성

vagrant를 이용하면 코드로써 VirtualBox VM을 설치할 수 있다. 

우분투 서버 VM을 스크립트를 이용한 자동 설치가 가능하다. 



### 목표 구성

쿠버네티스 테스트를 위해 3개의 VM을 준비한다. Master 노드 1개, Worker 노드 2개를 준비한다.

##### 공통구성

| 항목     | 내용                | 비고 |
| -------- | ------------------- | ---- |
| Base O/S | Ubuntu-20.04-Server |      |
| Username | k8s / k8s           |      |

##### VM별 구성

| 구분                  | vm1                 | vm2                 | vm3                 |
| --------------------- | ------------------- | ------------------- | ------------------- |
| 용도                  | 마스터 노드         | 워커 노드1          | 워커 노드2          |
| HOSTNAME              | k8s-master          | k8s-node1           | k8s-node2           |
| IP (eth1, NatNetwork) | 192.168.0.10        | 192.168.0.20        | 192.168.0.30        |
| IP (eth2, HostOnly)   | 192.168.1.10        | 192.168.1.20        | 192.168.1.30        |
| CPU / MEM /Disk       | 2 Core / 2GB / 10GB | 2 Core / 2GB / 10GB | 2 Core / 2GB / 10GB |



### VirtualBox 버전 선택

6.1.30 버전을 설치해야만 한다. 최신 버전인 6.1.34는 CPU Lock 오류가 발생한다.



### Virtualbox 네트워크 구성

Vagrant로 생성하는 VirtualBox VM에는 NAT 네트워크 1개가 기본적으로 생성된다. NIC는 eth0를 사용하며 IP는 10.0.2.15가 할당된다. 3개의 VM 모두 동일한 IP가 할당되며 해당 아이피로 상호간에 통신을 할 수는 없다.

2개의 사용자 정의 네트워크를 추가 구성한다. 

eth1은 NatNetwork로 192.168.0.0/24 대역이며 VM간 통신 및 인터넷 접근에 사용한다.

eth2는 HostOnly로 192.168.100.0/24 대역이며 Host PC에서 VM 내부 서비스를 호출하는데 사용한다.

NatNetwork를 사용하려면 Virtualbox 전역 환경에 `NAT Network`를 먼저 구성해야 한다.

`파일 > 환경설정 > 네트워크 > NAT 네트워크 추가` 메뉴로 접근하여 `NatNetwork`를 신규한다. CIDR은 `192.168.0.0/24`로 설정한다.



### Vagrant 설치

Windows의 CLI 패키지 설치 관리자인 chocolate를 이용한다.

```
choco install vagrant
```

(참고) vagrant 명령어

```
vagrant init | up | status | ssh | halt | destroy
```



### Vagrant를 이용한 Ubuntu VM 설치

먼저 `vagrant init`명령어로 초기 설정 파일 `Vagrantfile`을 생성한 후 아래 내용으로 저장한다.

(주의) 4번째 줄의 `nic = "Intel(R) Wi-Fi 6 AX200 160MHz"` 를 실습 PC의 NIC로 변경한다.

```ruby
# -*- mode: ruby -*-
# vi: set ft=ruby :

nic1 = "Intel(R) Wi-Fi 6 AX200 160MHz"
nic2 = "Intel(R) Wi-Fi 6E AX211 160MHz"
nic3 = "Intel(R) Wireless-AC 9560 160MHz #2"

Vagrant.configure("2") do |config|
  config.vm.define "k8s-master" do |config|
    config.vm.box = "generic/ubuntu2004"
    config.vm.hostname = "k8s-master"
    config.vm.network "public_network", ip: "192.168.0.10", bridge: ["#{nic1}", "#{nic2}", "#{nic3}"]
    config.vm.network "private_network", ip: "192.168.1.10", :adapter => 3
    config.vm.box_check_update = false
    config.vm.disk :disk, name: "disk1", size: "10GB", primary: true

    config.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-master"
      vb.cpus = 2
      vb.memory = "2048"  # Customize the amount of memory on the VM:
      vb.customize ["modifyvm", :id, "--nic2", "natnetwork"]
      vb.gui = false # Display the VirtualBox GUI when booting the machine
    end
  end

  config.vm.define "k8s-node1" do |config|
    config.vm.box = "generic/ubuntu2004"
    config.vm.hostname = "k8s-node1"
    config.vm.network "public_network", ip: "192.168.0.20", bridge: ["#{nic1}", "#{nic2}", "#{nic3}"]
    config.vm.network "private_network", ip: "192.168.1.20", :adapter => 3
    config.vm.box_check_update = false
    config.vm.disk :disk, name: "disk1", size: "10GB", primary: true

    config.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-node1"
      vb.cpus = 2
      vb.memory = "2048"  # Customize the amount of memory on the VM:
      vb.customize ["modifyvm", :id, "--nic2", "natnetwork"]
      vb.gui = false # Display the VirtualBox GUI when booting the machine
    end
  end

  config.vm.define "k8s-node2" do |config|
    config.vm.box = "generic/ubuntu2004"
    config.vm.hostname = "k8s-node2"
    config.vm.network "public_network", ip: "192.168.0.30", bridge: ["#{nic1}", "#{nic2}", "#{nic3}"]
    config.vm.network "private_network", ip: "192.168.1.30", :adapter => 3
    config.vm.box_check_update = false
    config.vm.disk :disk, name: "disk1", size: "10GB", primary: true

    config.vm.provider "virtualbox" do |vb|
      vb.name = "k8s-node2"
      vb.cpus = 2
      vb.memory = "2048"  # Customize the amount of memory on the VM:
      vb.customize ["modifyvm", :id, "--nic2", "natnetwork"]
      vb.gui = false # Display the VirtualBox GUI when booting the machine
    end
  end

  # Provision
  config.vm.provision "shell", inline: <<-SHELL
    # 실습용 계정 생성
    useradd -m -s /bin/bash -p $(perl -e 'print crypt("k8s", "salt")') k8s
    usermod -aG sudo k8s

    # git clone
    runuser -l k8s -c 'git clone https://github.com/grollcake/k8s-practice.git'

    # hosts 이름 등록 등
    bash /home/k8s/k8s-practice/p1-virtualbox-setup/scripts/init.sh
  SHELL
end
```



`vagrant up ` 명령어로 vm을 생성한다. 약 25~30분 가량이 소요된다.



### 참고 링크

* 쿠버네티스(kubernetes) 설치 및 환경 구성하기 https://medium.com/finda-tech/overview-8d169b2a54ff

* Virtual Box, Vagrant를 이용한 가상 머신 환경 만들기 https://medium.com/@dudwls96/virtual-box-vagrant%EB%A5%BC-%EC%9D%B4%EC%9A%A9%ED%95%9C-%EA%B0%80%EC%83%81-%EB%A8%B8%EC%8B%A0-%ED%99%98%EA%B2%BD-%EB%A7%8C%EB%93%A4%EA%B8%B0-478b8871e474