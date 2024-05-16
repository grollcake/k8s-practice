# Practice note

### p0-prepare (약 7분)

* Choco, Winget 설명
* 설치되는 프로그램 용도 설명
* 바탕화면에 설치된 프로그램 확인시켜주기
* Virtuabox 전역 설정 설명 - 호스트키 조합
* 설치 완료 후 Reboot
* `vagrant box add generic/ubuntu2004`
* Hyper-V 검사점 생성 (demo-p0-done)



### p1-virtualbox-setup (약 7분)

* `code .`
* Virtualbox NAT 네트워크 설명 - k8s-natnetwork
* Tabby로 Windows 터미널 실행
* VM NAT 네트워크에 포트포워딩 설명
* Vagrant 오류 시 `vagrant box remove generic/ubuntu2004`  `vagrant reload`
* Tabby SSH 연결 생성
* Hyper-V 검사점 생성 (demo-p1-done)



### p2-k8s-cluster-setup (약 6분)

* 클러스터 구성 후 점검 명령어

  ```bash
  kubectl get nodes -o wide  # watch -n 2 kubectl get nodes -o wide
  kubectl get pods -n kube-system
  kubectl get po -A     # 또는 --all-namespaces
  kubectl get apiservices
  kubectl describe svc   # Endpoints는 API서버에 대한 접속 경로
  ```

* Hyper-V 검사점 생성 (demo-p2-done)



### p3-dashboard-setup

* https://192.168.0.10:30443/
* OpenLens
* Hyper-V 검사점 생성 (demo-p3-done)



### p4-demo-service-deploy

* kubectl wait pod --for=condition=Ready -l app=imaginary --timeout=5m

* master, node1, node2에서 모두 시연

  ```
  curl -H "API-Key: awesome-k8s" 127.0.0.1:30000/health
  ```
  
* postman: 192.168.0.10

* Hyper-V 검사점 생성 (demo-p4-done)



### p5-load-test (212초)

* Lens 확인: Services, Endpoints
* 왜 9000? https://github.com/h2non/imaginary/blob/master/Dockerfile
* 진척 확인

```bash
python3 -m http.server
```

* Hyper-V 검사점 생성 (demo-p5-done)



### p6-hpa (180초)

```
kubectl get hpa -w
```

* Hyper-V 검사점 생성 (demo-p6-done)



### p7-ingress

* https://sslip.io/

```bash
# ingress 상태 조회
kubectl get ingress

# EXTERNAL-IP 할당 모니터링
kubectl get svc -n ingress-nginx

# 외부 연결 도메인 확인
kubectl describe ingress
```

* http://dashboard.192.168.0.100.sslip.io
* http://imaginary.192.168.0.100.sslip.io



### p8-todo-app

* `kubectl get all,ep,ingress -o wide -n todo-app`
* OpenLens에서 todo-app 서비스 수정
* http://todo.192.168.0.100.sslip.io



### p9-persistent-volume

* k8s-nfs ssh 접속
* cd /var/nfs_storage
* python3 -m http.server
* Hyper-V 검사점 생성 (demo-p9-done)



### p10-wikijs

* watch kubectl get all,pvc,ep,ingress -o wide -n wikijs-app

