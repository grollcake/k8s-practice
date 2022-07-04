# P0-Prepare: 테스트 환경 준비

실습에 필요한 S/W를 Windows PC에 미리 설치한다.



### 1. choco 설치

[Chocolatey](https://chocolatey.org/)는 Linux에서의 [apt(apt-get)](https://salsa.debian.org/apt-team/apt), [yum](http://yum.baseurl.org/index.html)이나 macOS에서의 [Homebrew](https://brew.sh/index_ko.html)처럼 패키지를 설치/업데이트/제거 등 관리하는 데에 사용하는 Windows용 프로그램이다. CMD 창에서 간단한 명령어만으로 프로그램들을 설치할 수 있다.

**CMD를 관리자 권한으로 실행**한 후에 아래 명령어로 설치한다.

```
@"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command " [System.Net.ServicePointManager]::SecurityProtocol = 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
```

choco 설치 확인. 명령어를 찾지 못한다면 시스템 Path를 못 읽어서 그런거니까 CMD를 재실행한다.

```
choco -V
```



### 2. Virtualbox 설치

쿠버네티스를 우분투 서버에 설치하여 테스트를 진행할 것이다. 윈도우에서 우분투 서버를 설치하기 위해 virtualbox를 먼저 설치한다.
최신 버전의 virtualbox에서는 cpu lock 문제가 빈번하게 발생하므로 옛 버전을 설치토록 한다.

```
choco install -y virtualbox --version 6.1.30
```



### 3. Vagrant 설치

`vagrant`를 이용하면 code로 VirtualBox VM을 생성할 수가 있다. 

```
choco install -y vagrant
```



### 4. Postman 설치

`postman`으로 API 호출을 쉽게 테스트해볼 수 있다.

```
choco install -y postman
```



### 5. Python 설치

부하 테스트는 파이썬으로 작성되어 있어 실행하려면 필요하다.

```
choco install -y python
```



### 6. Typora 설치

실습 설명서는 마크다운(md)으로 작성되어 있는데 편집기는 typora가 제일 좋다.

```
choco install -y typora
```



### 7. Lens 설치

쿠버네티스를 관리할 수 있는 설치형 프로그램

```
choco install -y lens
```

