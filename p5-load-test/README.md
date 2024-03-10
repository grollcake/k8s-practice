# p5-load-test

k8s에 배포된 imaginary pod에 이미지 변환을 100회 요청하여 성능을 측정한다.

hpa 적용 유무에 따른 성능을 측정하기 위한 용도이다.



### 1. 방식

* imaginary를 이용하여 jpg 이미지를 png로 변환, 사이즈 변환, 워터마크 삽입을 한다.
  * 입력 파일: `load-test/sample.jpg`
  * 변환 파일: `load-test/converted/converted-{n}.png`

* 총 100회를 실행한다.
* 동시 처리건수를 사용자가 지정할 수 있다 (권고는 5건)



### 2. 준비

* k8s-master 노드에서 실행한다.
  
* 로드 테스트 프로그램은 파이썬 작성함: `load-test.py`
  
* 파이썬과 의존성 패키지 먼저 설치
  
  ```bash
  cd load-test
  sudo apt install -y python3-pip
  pip3 install -r requirements.txt
  ```
  



### 3. 실행

k8s-master 노드에서 실행한다. 실행이 완료되면 총 소요시간이 출력된다.

```bash
python3 load-test.py
```

변환된 이미지는 다음의 명령으로 확인할 수 있다.

```
python3 -m http.server
# 브라우저에서 http://192.168.0.10:8000 접속
```

