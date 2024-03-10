# p4-deom-service-deploy

이미지 변환 오픈소스인 imaginary를 k8s 클러스터에 배포해본다.



### 1. imaginary deployment

* imaginary pod 한개를 배포해본다.
  * 이미지는 `h2non/imaginary:latest`를 사용한다.
  * 식별자 라벨로 `app=imaginary`를 사용한다.
  * 9000번 포트에서 서비스하고, API-KEY는 `awesome-k8s`로 지정
  * 서비스가 준비되었는지 확인하기 위해 `readinessProbe`를 이용하며 `/health` 엔드포인트로 점검한다.

* 아래 내용을 `imaginary-deployment.yml` 파일로 저정 후 `kubectl apply -f imaginary-deployment.yml` 명령으로 배포한다.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: imaginary-deployment
spec:
  replicas: 1
  selector:
    matchLabels:
      app: imaginary
      tier: app
  template:
    metadata:
      labels:
        app: imaginary
        tier: app
    spec:
      containers:
        - name: imaginary
          image: h2non/imaginary:latest
          args: [ "-enable-url-source", "-concurrency", "5", "-key", "awesome-k8s" ]
          readinessProbe:
            httpGet:
              path: /health
              port: 9000
              httpHeaders:
                - name: API-Key
                  value: awesome-k8s
          resources:
            requests: 
              cpu: "250m"
            limits:
              cpu: "500m"
```

* 생성 확인 명령어: `kubectl get pods,deployments`



### 2. imaginary service

* 외부에서 접속 가능하도록 NodePort 서비스를 30000번 포트에 구성한다.
  * 식별자 라벨 `app=imaginary`로 선택한다.

* 아래 내용을 `imaginary-service.yml` 파일로 저정 후 `kubectl apply -f imaginary-service.yml` 명령으로 배포한다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: imaginary-np
spec:
  type: NodePort
  ports: 
    - port: 9000
      protocol: TCP
      nodePort: 30000
  selector:
    app: imaginary
```

* 생성 확인 명령어: `kubectl get services`



### 3. 접속 테스트

curl로 접속 테스트를 해볼 수 있다. NodePort로 구성했기 때문에 Master, node1, node2 모두에서 접속할 수 있다.

* curl -H "API-Key: awesome-k8s" 192.168.0.10:30000/health
* curl -H "API-Key: awesome-k8s" 192.168.0.20:30000/health
* curl -H "API-Key: awesome-k8s" 192.168.0.30:30000/health



