# oha 기반의 단일 PC 부하 테스트 
- git repo: https://github.com/hatoo/oha

## 테스트 유형 별 사용법
- baseline 테스트 ( 기본 성능 측정 )
    ```sh
    oha -n 100 -c 10 -z 30s \
    --disable-keepalive \
    -j "https://api.example.com/endpoint" > baseline_results.json
    ```
- stability 테스트 : 장시간 안정성 확인 ( 높은 z값 )
    ```bash
    oha -n 10000 -c 50 -z 300s \
        --disable-keepalive \
        --timeout 30s \
        -j "https://api.example.com/endpoint" > stability_test.json
    ```
- 과부하 테스트 ( 높은 c 값 )
    ```bash
    oha -n 5000 -c 200 -z 120s \
        --disable-keepalive \
        --timeout 60s \
        -j "https://api.example.com/endpoint" > stress_test.json  
    ```
- 타임아웃 테스트
    ```bash
    oha -n 1000 -c 150 -z 60s \
    --disable-keepalive \
    --timeout 5s \
    -j "https://api.example.com/slow-endpoint" > timeout_test.json
  ```
  - 서버 측의 에러만 실패(timeout등) 뿐만 아니라 클라이언트 단의 timeout도 실패로 집계하고자 할 때 적용
  - 실제 서비스에 가깝게 테스트 하려면 적용하는 것이 좋다.
  ```bash
  # 빠른 응답이 요구되는 API 테스트
  oha -n 1000 -c 100 -z 30s --timeout 5s
  
  # 검색 등의 API 테스트
  oha -n 1000 -c 100 -z 30s --timeout 10s
  
  # 파일 처리 등의 API 테스트
  oha -n 1000 -c 100 -z 30s --timeout 30s
  ```
- POST 메소드 테스트
  ```bash
  oha -n 1000 -c 150 -z 60s \
    --disable-keepalive \
    --timeout 5s \
    -j "https://api.example.com/slow-endpoint" > timeout_test.json
  ```
  
## disable-keepalive 옵션
- 단일 PC에서 --disable-keepalive를 사용하는 것이 다수 클라이언트의 연결 패턴을 더 잘 시뮬레이션 한다. TCP 연결을 재사용하지 않고 매번 새로운 연결을 생성하기 때문. 
- 따라서 disable-keepalive 옵션을 쓰면 쓰지 않았을 떄에 비해 아래와 같은 포인트를 테스트할 수 있다. 
  - 서버의 동시 연 처리 능력 및 connection pool 이 적정한 지 
  - TCP 연결 생성/종료에 대한 서버 처리 능력 
  - 리소스 해제와 가비지 컬렉션이 잘 되는 지 네트워크 스택 성능이 충분한 지

## z 옵션 : 시간 제한 여부
- 시간 제한이 있는 테스트 : 정확히 n개의 요청 수행
  ```bash
  # 정확히 1000개의 요청만 수행
  oha -n 1000 -c 100 --disable-keepalive "https://api.example.com"
  ```
- 시간 제한이 없는 테스트 : n초 동안 최대한 많은 요청 수행
  ```bash
  # 60초 동안 최대한 많은 요청 수행 (목표: 1000개)
  oha -n 1000 -c 100 -z 60s --disable-keepalive "https://api.example.com"
  ```
### 시간 제한 있는 테스트
- z옵션을 주는 것이 일반적
- 정해진 시간 동안의 시스템 처리 능력 (throughput) 측정
- 실제 운영 환경과 비슷한 지속적 부하 시뮬레이션
- 목표 요청 수를 초과할 수 있고, 그에 따라 결과 해석이 더 복잡할 수 있음 

#### 평가지표 및 예시
  - 성공률(실패율): 성공적으로 처리된 총 요청 수
  - RPS : 초당 처리된 요청 수 
    - 시스템이 안정적으로 처리할 수 있는 최대 RPS는 얼마인가를 측정하기에 적합함.
  - 평균 응답 시간(분포)
  - 평가 Example
    ```json
    좋은 성능 CASE:
      - 60초 동안 1500건 처리 (목표 1000 초과 달성)
      - RPS: 25
      - 성공률: 98%
      - 평균 응답시간: 40ms
    나쁜 성능 CASE:
      - 60초 동안 800건 처리 (목표 1000 미달)
      - RPS: 13
      - 성공률: 85%
      - 평균 응답시간: 150ms
    ```

### 시간 제한 없는 테스트
- 긴 처리시간이 걸리는 요청까지 다 기다려보면서 측정하고자 할 때 적용
  - RPS 지표 평가 시, 긴 처리시간의 요청에 따라 왜곡될 수 있음
