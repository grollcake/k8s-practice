# Practice note

### p0-prepare (약 7분)

* Choco, Winget 설명
* 설치되는 프로그램 용도 설명
* 설치 완료 후 Reboot 필요
* `vagrant box add generic/ubuntu2004`
* Hyper-V 검사점 생성 (p0-done)



### p1-virtualbox-setup (약 7분)

* Tabby로 Windows 터미널 실행
* `code .`
* Virtuabox 전역 설정 설명 - 호스트키 조합
* Virtualbox NAT 네트워크 설명 - k8s-natnetwork
* VM NAT 네트워크에 포트포워딩 설명
* Vagrant 오류 시 `vagrant box remove generic/ubuntu2004`  `vagrant reload`
* Tabby SSH 연결 생성



### p2-k8s-cluster-setup (약 6분)

* 클러스터 구성 후 점검 명령어

  ```bash
  kubectl get nodes -o wide  # watch -n 2 kubectl get nodes -o wide
  kubectl get pods -n kube-system
  kubectl get po -A     # 또는 --all-namespaces
  kubectl get apiservices
  kubectl describe svc   # Endpoints는 API서버에 대한 접속 경로
  ```

  

### p3-dashboard-setup



### p4-demo-service-deploy



### p5-load-test

```bash
python3 -m http.server
```



### p6-hpa

```
kubectl get hpa -w
```



### p7-ingress



### p8-todo-app



### p9-persistent-volume



### p10-wikijs

