from glob import glob
from operator import mod
import os
import time
import requests
import threading


IMAGINARY_ENDPOINT = "http://192.168.1.10:30000"
ORIGINAL_IMAGE_PATH = os.path.join(os.path.dirname(__file__), 'originals')
CONVERTED_IMAGE_PATH = os.path.join(os.path.dirname(__file__), 'converted')


# 원본 이미지 폴더의 모든 이미지 full path를 배열로 만들어 반환
def get_original_images():
    image_files = [os.path.join(ORIGINAL_IMAGE_PATH, f)
                   for f in os.listdir(ORIGINAL_IMAGE_PATH)]
    return image_files


# 이미지 변환 작업
# 1. PNG로 변환
# 2. 사이즈 변환 w/ crop: 500 * 500
# 3. Water mark 삽입
def imaginary_convert(file: str):

    # 1. 준비
    start_time = time.time()
    filename = os.path.basename(file)
    print(f'  {filename} 이미지 작업 시작..')

    # 2. PNG로 변환
    url = IMAGINARY_ENDPOINT + '/convert'
    headers = {'API-Key': 'awesome-k8s'}
    params = {'type': 'png'}
    files = [('file', (filename, open(file, 'rb')))]
    response = requests.post(url, headers=headers, params=params, files=files)
    if response.status_code != 200:
        print(f'  E: {filename} 이미지를 PNG로 변환 중 오류 발생')
        return

    # 3. 사이즈 변환
    url = IMAGINARY_ENDPOINT + '/resize'
    params = {'height': 500, 'width': 500, 'nocrop': False, 'type': 'png'}
    files = [('file', (filename, response.content))]
    response = requests.post(url, headers=headers, params=params, files=files)
    if response.status_code != 200:
        print(f'  E: {filename} 이미지를 Resize 중 오류 발생')
        return

    # 4. water mark 삽입
    url = IMAGINARY_ENDPOINT + '/watermark'
    params = {'text': 'newgw2022', 'textwidth': 200,
              'opacity': 1.0, 'noreplicate': True}
    files = [('file', (filename, response.content))]
    response = requests.post(url, headers=headers, params=params, files=files)
    if response.status_code != 200:
        print(f'  E: {filename} 이미지에 워터마크 삽입 중 오류 발생')
        return

    # 5. target 경로에 완료 이미지 생성
    filename_without_ext = os.path.splitext(filename)[0]
    target_file = os.path.join(
        CONVERTED_IMAGE_PATH, f'{filename_without_ext}.png')
    open(target_file, 'wb').write(response.content)

    # 6. 정리
    print(
        f'  {filename} 이미지 처리 완료. 소요시간: {time.time() - start_time:.1f} 초')


# Todo: 초당 5건씩 API 호출
def main():
    # 0. 작업 유형 입력받기
    concurrent_cnt = int(input('동시 처리 건수를 입력하세요(1~20): '))
    assert concurrent_cnt >= 1 and concurrent_cnt <= 20, '1~20 사이의 값을 입력하세요'

    # 1. 이전 파일 모두 지우기
    for f in glob(os.path.join(CONVERTED_IMAGE_PATH, "*")):
        os.unlink(f)

    # 2. 시작 시간 측정
    start_time = time.time()

    # 3. 변환 대상 이미지 파일 목록 생성
    image_files = get_original_images()

    # 4. 변환 작업 병렬 처리
    threads = []
    for image_file in image_files:
        t = threading.Thread(target=imaginary_convert, args=[image_file])
        t.start()
        threads.append(t)
        if len(threads) % concurrent_cnt == 0:
            print(f'  {len(threads)}개 작업이 완료되길 대기 중...')
            [t.join() for t in threads]
            threads.clear()

    # 5. 소요시간 출력
    print(
        f'모든 작업 완료. 소요시간: {time.time() - start_time:.1f}초')


if __name__ == '__main__':
    main()
