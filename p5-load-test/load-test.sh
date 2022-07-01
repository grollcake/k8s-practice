#!/bin/bash

# root가 아닌 유저로 실행해야 한다.
if (( $EUID == 0 )); then
    echo "Please run as regular user, not root"
    exit
fi

# 현재 스크립트 경로로 변경
cd $( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

##########################################################
# Step 1. Python 모듈 설치 후 실행
##########################################################

# requests 모듈이 설치되지 않은 경우 설치부터 한다.
if ! ( $(python3 -c 'import requests' 2> /dev/null) ); then
    esudo apt install -y python3-pip
    pip3 install -r load-test/requirements.txt
fi

##########################################################
# Step 2. load-test.py 실행
##########################################################
cd load-test
python3 load-test.py
