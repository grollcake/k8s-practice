# p6-hpa

HPA(Horizontal Pod Autoscaling)을 적용한다.



### 1. Metric Server 설치

k8s-master 노드에서 실행한다.

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```



##### [문제해결] 설치 후 apiservices를 확인해보면 False (MissingEndpoints) 오류가 확인된다.

```
kubectl get apiservices
 ...
 v1beta1.metrics.k8s.io  kube-system/metrics-server False (MissingEndpoints) 10s
 ...
```

tls 인증서가 없어서 발생하는 것으로써, tls 통신을 안해도 되도록 metrics-server의 Deployment에 insecure-tls 옵션을 추가한다.

```
kubectl patch deployment metrics-server -n kube-system --type 'json' -p '[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
```

위 명령어를 실행하면 1~2분 내에 False가 True로 변경된다.



Metric server가 적용됐는지 확인해본다.

```
kubectl top nodes
kubectl top pods
```



### 2. hpa 배포

imaginary를 hpa 설정 파일을 `imaginary-hpa.yml`로 생성한다.

* 최소 레플리카는 1, 최대 10개로 설정
* cpu 사용량이 80%인 경우 Scale out하도록 설정

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: imaginary-hpa-cpu
spec:
  maxReplicas: 10 # 최대 레플리카 수
  minReplicas: 1 # 최소 레플리카 수
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: imaginary-deployment
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 80 # 평균 CPU 사용량이 80% 이상인 경우 Scale Out, 이하면 Scale In
```

hpa 배포

```
kubectl apply -f imaginary-hpa.yml
```

hpa 상태를 조회해본다.

```
kubectl get hpa -w
```



### 3. hpa 테스트

p5-load-test를 재실행하면 hpa가 어떻게 적용되는지 확인해볼 수 있다.
