# p7-ingress

Ingress는 클러스터 외부에서 클러스터 내의 서비스로 HTTP와 HTTPS 트래픽을 라우팅하는 플러그인이다.  Ingress를 사용하면 URL, 경로, 호스트 이름을 기준으로 트래픽을 적절한 서비스로 전달할 수 있으며, 이를 통해 단일 IP 주소를 사용하여 클러스터 내의 여러 서비스에 접근할 수 있게 된다. Ingress는 보안, SSL/TLS 인증서 관리, 도메인 기반 가상 호스팅 등의 고급 트래픽 관리 기능도 제공하여, 외부에서 클러스터 내부로의 접근을 보다 세밀하게 제어할 수 있게 한다.



Ingress로 사용할 수 있는 컨트롤러(또는 리버스 프록시)에는 다음과 같은 것들이 있다.

1. **NGINX Ingress Controller**: 가장 인기 있는 오픈 소스 리버스 프록시 중 하나로, 고성능, 확장성, 유연성을 제공합니다.
2. **HAProxy Ingress**: HAProxy는 고성능 로드 밸런서로서, Kubernetes 환경에서도 효율적인 트래픽 관리와 안정성을 제공하는 Ingress 컨트롤러로 사용됩니다.
3. **Traefik**: Traefik도 Kubernetes Ingress 컨트롤러로 널리 사용되며, 자동화된 SSL 인증서 관리(예: Let's Encrypt), 마이크로서비스와 함께 사용하기 좋은 다양한 기능을 제공합니다.
4. **Istio Ingress Gateway**: 서비스 메시 프레임워크인 Istio의 일부로, Istio Ingress Gateway는 더 복잡한 라우팅, 보안 정책, 서비스 간 통신 관리 등을 제공합니다.
5. **Contour**: Envoy 프록시를 기반으로 하는 Ingress 컨트롤러로, 다양한 HTTP 관련 기능을 제공하며, 특히 다중 테넌트 환경에서 강력한 성능을 발휘합니다.
6. **Kong Ingress Controller**: Kong API Gateway를 기반으로 한 Ingress 컨트롤러로, API 관리 기능을 포함하여, 인증, 율 제한, 분석 등 다양한 기능을 제공합니다.



### 1. 준비

MetalLB와 같은 온프레미스 로드밸런서를 쓰기 위해 proxy 설정 중 strict ARP mode를 enable로 변경한다.

```bash
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

> **ChatGPT 답변**
>
> 이 명령어는 `kube-proxy`의 설정을 수정하기 위해 사용됩니다. 구체적으로는, `kube-system` 네임스페이스에 있는 `kube-proxy` ConfigMap의 `strictARP` 설정을 `false`에서 `true`로 변경한 뒤, 변경된 설정을 클러스터에 적용합니다. 여기서 `strictARP`는 ARP(주소 확인 프로토콜)의 엄격한 처리를 활성화하는 설정입니다.
>
> `strictARP: true`로 설정하는 이유는 주로 Kubernetes 클러스터에서 네트워크 로드 밸런서를 더 효과적으로 활용하기 위해서입니다. 특히, MetalLB와 같은 온-프레미스에서 실행되는 로드 밸런서를 사용하는 환경에서 중요합니다. `strictARP`가 활성화되면, ARP 응답이 더 엄격하게 제어되어, 클러스터 내의 가상 IP 주소에 대한 ARP 요청에 대해 기대하는 방식으로만 응답하게 됩니다. 이는 네트워크 안정성과 성능을 향상시키는데 도움을 줄 수 있습니다.



### 2. ingress 설치

NGINX Ingress controller를 cloud 유형으로 설치한다.

```
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.0/deploy/static/provider/cloud/deploy.yaml
```

설치에는 약간 시간이 걸린다. 완료 여부는 다음 명령으로 확인한다.

```
kubectl wait pod --for=condition=Ready -l app.kubernetes.io/component=controller -n ingress-nginx --timeout=5m

# 상태 조회
kubectl get all -n ingress-nginx
```



### 3. MetalLB 설치

Virtualbox를 이용한 실습 환경에는 외부 로드 발란서가 없으니까 S/W 방식인 MetalLB를 설치토록 한다.

```
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/namespace.yaml
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
```

ingress EXTERNAL-IP에 192.168.1.100~200을 할당한다.

* 아래 내용을 `metallb-configmap.yml`로 저장하고 `kubectl apply -f metallb-configmap.yml`로 적용한다.

```
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
      - 192.168.0.100-192.168.0.200
```



### 4. ingress 적용

> (참고) sslip.io
>
> sslip.io는 호스트 이름에 내장된 IP 주소를 포함한 쿼리를 받았을 때, 해당 IP 주소를 반환하는 DNS(도메인 이름 시스템) 서비스이다.
>
> | Hostname / URL                                               | IP Address  | Notes                                           |
> | :----------------------------------------------------------- | :---------- | :---------------------------------------------- |
> | [https://52.0.56.137.sslip.io](https://52.0.56.137.sslip.io/) | 52.0.56.137 | dot separators, sslip.io website mirror (IPv4)  |
> | [https://52-0-56-137.sslip.io](https://52-0-56-137.sslip.io/) | 52.0.56.137 | dash separators, sslip.io website mirror (IPv4) |
> | www.192.168.0.1.sslip.io                                     | 192.168.0.1 | subdomain                                       |
> | www.192-168-0-1.sslip.io                                     | 192.168.0.1 | subdomain + dashes                              |



dashboard 서비스를 `dashboard.192.168.0.100.sslip.io` 도메인으로 접속할 수 있도록 Ingress를 적용한다.

* 아래 내용을 `dashboard-ingress.yml`로 저장하고 `kubectl apply -f dashboard-ingress.yml`로 적용한다.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: dashboard-ingress
  namespace: kubernetes-dashboard
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - host: dashboard.192.168.0.100.sslip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kubernetes-dashboard
                port:
                  number: 443
```



imaginary 서비스를 `imaginary.192.168.0.100.sslip.io` 도메인으로 접근할 수 있도록 Ingress를 적용한다.

* 우선 서비스부터 적용한다. 
* 아래 내용을 `imaginary-service.yml`로 저장하고 `kubectl apply -f imaginary-service.yml`로 적용한다.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: imaginary-svc
spec:
  ports: 
    - port: 9000
      protocol: TCP
  selector:
    app: imaginary
```

* `imaginary-svc`의 9000번 포트에 접근하기 위한 ingress를 생성한다.
* 아래 내용을 `imaginary-ingress.yml`로 저장하고 `kubectl apply -f imaginary-ingress.yml`로 적용한다.

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: imaginary-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
    - host: imaginary.192.168.0.100.sslip.io
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: imaginary-svc
                port:
                  number: 9000
```



상태 조회

```bash
# ingress 상태 조회
kubectl get ingress

# EXTERNAL-IP 할당 모니터링
kubectl get svc -n ingress-nginx

# 외부 연결 도메인 확인
kubectl describe ingress
```



### 5. 도메인으로 접속해보기

* https://dashboard.192.168.0.100.sslip.io
* http://imaginary.192.168.0.100.sslip.io
