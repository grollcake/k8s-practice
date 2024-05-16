# K8S Practice

![image-20240516193144963](assets\practice-blueprint.png)




>유튜브 44Bit 채널에서 제공한 **초보를 위한 쿠버네티스 안내서**를 요약하였다.
>
>아래 영상을 미리 시청한다면 이해에 큰 도움이 될 것이다.
>
>https://youtube.com/playlist?list=PLIUCBpK1dpsNf1m-2kiosmfn2nXfljQgb&si=Jy1CsjPC8a_bIKFS



#### kubernetes

* 컨테이너를 **쉽고 빠르게 배포ㆍ확장**하고 **관리를 자동화**해주는 오픈소스 플랫폼
* 구글이 컨테이너 배포 시스템으로 사용하던 **borg를 기반으로 만든 오픈소스**로 2015년 1.0 릴리즈
* 현재는 CNCF(Cloud Native Computing Foundation)으로 이관되어 완전한 오픈소스化



#### 패러다임의 변화

* 이제 개발자나 클라우드에 있어 리눅스가 더 이상 중요하지 않다.
* **쿠버네티스가 곧 새로운 운영체제**이며 플랫폼이다.
* 쿠버네티스는 De Facto (사실상의 표준)
* 쿠버네티스에 기반한 컨테이너 오케스트레이션 플랫폼들
  * **Rancher** by SUSE, **Red Hat OpenShift** by IBM, **Tanzu** by VMware
  * **EKS** by Amazon, **AKS** by Azure, **GKE** by Google



#### Cloud Native

* 컨테이너
* 마이크로 서비스
* 서비스 메시 (MSA에서 서비스간의 통신을 용이하게 하는 인프라 계층)
* API
* DevOps
* 언제나 대체 가능한 인프라



#### K8S 구성 요소

* 마스터 노드 구성 요소

  * etcd: 분산된 키-값 스토어로 k8s 클러스터의 모든 상태와 데이터 정보를 저장

  * API Server: 클러스터와의 모든 통신의 중심점으로 REST API 요청 처리

  * Scheduler: 생성된 새로운 파드(Pods)를 감지하고, 실행할 노드(Node)를 결정하여 할당

  * Controller: 원하는 상태로 유지하기 위해 지속적으로 감시하고 조정 (복제 컨트롤러, 노드 컨트롤러, 엔드포인트 컨트롤러, ...)


* 워커 노드 구성 요소

  * Kubelet: 각 노드에서 Pod를 실행/중지하고 상태를 체크. CRI(docker, containerd, CRI-O)와 상호작용.

  * Proxy: 네트워크 프록시와 부하분산. 성능 이유로 iptables 또는 IPVS 사용

* 애드온

  * CNI (네트워크)
  * DNS (도메인, 서비스 디스커버리)
  * 대시보드 (시각화)



#### K8S 오브젝트들

* **Pod**: 고유의 IP할당. 여러개의 컨테이너가 하나의 Pod에 속할 수 있음
* **ReplicaSet**: 신규 Pod를 생성하거나 기존 pod를 제거하여 원하는 수(Replicas)를 유지
* **Deployment**: 배포 버전을 관리. ReplicaSet을 감싼 상위 오브젝트
* **Service - ClusterIP**: 클러스터 내부에서 사용하는 프록시. pod에 대한 리버스 프록시 개념.
* **Service - NodePort**: 노드(host)에 노출되어 외부에서 접근 가능한 서비스. ClusterIP에 대한 리버스 프록시 개념.
* **Service - LoadBalancer**: 하나의 IP주소를 외부에 노출. NodePort에 대한 리버스 프록시 개념.
* **Ingress**: 도메인 이름(또는  경로)를 이용하여 라우팅 처리. Ingress만 있으면 NodePort 없이도 ClusterIP로 연결 가능. Nginx, HAProxy 등 사용.
* Node
* Namespace
* Endpoint
* StatefulSet
* Volume
* DaemonSet
* Job



#### 자주쓰는 명령어

```bash
kubectl run whoami --image subicura/whoami:1
kubectl get po   # pod, pods, ns, 
kubectl get pods -o wide  # -o yaml, -o json
kubectl get ns
kubectl logs -f whoami-<xxxx>
kubectl exec -it whoami-<xxxx>
kubectl describe pods whoami-<xxxx>
kubectl delete pods whoami-<xxxx>
kubectl get all -o wide
kubectl get all,ingress -o wide -n <namespace>
```

