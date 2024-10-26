#!/bin/bash

# 1. 설정 변수
RESULTS_DIR="load_test_results_$(date +"%Y%m%d_%H%M")"
SUMMARY_CSV="$RESULTS_DIR/test_summary.csv"
API_URL="https://www.hyundai.com/kr/ko/e"

# 2. 초기화 함수
initialize_test() {
    mkdir -p "$RESULTS_DIR"
    echo "Concurrent Users,Target Requests,Successful Requests,Success Rate,Avg Response Time(ms),P95 Response Time(ms),RPS,Test Duration(s)" > "$SUMMARY_CSV"
    echo "Test initialized at $(date)"
}

# 3. 결과 분석 함수
analyze_results() {
    local CONCURRENT=$1
    local TEST_FILE=$2
    
    echo "Analyzing results for $CONCURRENT concurrent users..."
    
    # 테스트 실행 정보 추출
    local TEST_DURATION=$(jq -r '.summary.total' "$TEST_FILE")
    local TARGET_REQUESTS=$((CONCURRENT * 20))
    local SUCCESS_COUNT=$(jq -r '.statusCodeDistribution["200"] // 0' "$TEST_FILE" | cut -d. -f1)
    
    # 성능 메트릭 추출
    local AVG_RESPONSE=$(jq -r '.summary.average' "$TEST_FILE")
    local P95_RESPONSE=$(jq -r '.latencyPercentiles.p95' "$TEST_FILE")
    local RPS=$(jq -r '.summary.requestsPerSec' "$TEST_FILE")
    
    # 성공률 계산
    local SUCCESS_RATE=0
    if [ $TARGET_REQUESTS -gt 0 ] && [ $SUCCESS_COUNT -ge 0 ]; then
        SUCCESS_RATE=$(awk "BEGIN {printf \"%.2f\", ($SUCCESS_COUNT/$TARGET_REQUESTS)*100}")
    fi
    
    # 결과 출력
    echo "=== Test Results for $CONCURRENT concurrent users ==="
    echo "Test Execution Summary:"
    echo "- Target Requests: $TARGET_REQUESTS"
    echo "- Total Test Duration: $TEST_DURATION seconds"
    echo "- Successful Requests: $SUCCESS_COUNT"
    echo "- Success Rate: $SUCCESS_RATE%"
    echo
    echo "Performance Metrics:"
    echo "- Average Response Time: $AVG_RESPONSE ms"
    echo "- 95th Percentile Response Time: $P95_RESPONSE ms"
    echo "- Requests Per Second (RPS): $RPS"
    echo
    echo "Test Efficiency:"
    echo "- Time per Request: $(awk -v time="$TEST_DURATION" -v reqs="$TARGET_REQUESTS" 'BEGIN {printf "%.2f", (time/reqs)*1000}') ms (avg)"
    echo "- Actual RPS: $(awk -v time="$TEST_DURATION" -v reqs="$TARGET_REQUESTS" 'BEGIN {printf "%.2f", reqs/time}')"   

    # 에러 분포 확인 및 출력
    local ERROR_DISTRIBUTION=$(jq -r '.errorDistribution | to_entries | map("\(.key): \(.value)") | join(", ")' "$TEST_FILE")
    if [ ! -z "$ERROR_DISTRIBUTION" ]; then
        echo
        echo "Error Distribution:"
        echo "- $ERROR_DISTRIBUTION"
    fi
    echo "----------------------------------------"
    
    # CSV에 결과 추가
    echo "$CONCURRENT,$TARGET_REQUESTS,$SUCCESS_COUNT,$SUCCESS_RATE,$AVG_RESPONSE,$P95_RESPONSE,$RPS,$TEST_DURATION" >> "$SUMMARY_CSV"
    
    # 성능 한계 체크
    if [ $(awk "BEGIN {print ($SUCCESS_RATE < 95) ? 1 : 0}") -eq 1 ]; then
        echo "⚠️ WARNING: Success rate below 95% ($SUCCESS_RATE%)"
        return 1
    fi
    
    if [ $(awk "BEGIN {print ($P95_RESPONSE > 1000) ? 1 : 0}") -eq 1 ]; then
        echo "⚠️ WARNING: P95 response time above 1000ms ($P95_RESPONSE ms)"
        return 1
    fi
    
    return 0
}

# 4. 단일 부하 테스트 실행 함수
run_load_test() {
    local CONCURRENT=$1
    local TARGET_REQUESTS=$((CONCURRENT * 2))
    local TEST_FILE="$RESULTS_DIR/load_test_c${CONCURRENT}.json"
    
    echo "=== Starting test with $CONCURRENT concurrent users ==="
    echo "Target requests: $TARGET_REQUESTS"
    echo "$(date): Test started"
    
    oha -n $TARGET_REQUESTS -c $CONCURRENT \
        --disable-keepalive \
        -j "$API_URL" > "$TEST_FILE"
        
    if [ $? -ne 0 ]; then
        echo "Error: oha command failed"
        return 1
    fi
    
    analyze_results $CONCURRENT $TEST_FILE
    return $?
}

# 5. 메인 실행 부분
main() {
    echo "Starting progressive load test for Hyundai website..."
    initialize_test
    
    for CONCURRENT in 70; do
        run_load_test $CONCURRENT
        if [ $? -eq 1 ]; then
            echo "System limit detected at $CONCURRENT concurrent users"
            echo "Stopping test due to performance degradation"
            break
        fi
        
        echo "Cooling down for 15 seconds..."
        sleep 15
    done
    
    # 결과 시각화 호출
    if command -v python3 &> /dev/null; then
        echo "Generating visualization..."
        python3 visualize_results.py "$RESULTS_DIR"
        echo "Results visualization saved to: $RESULTS_DIR/load_test_results.png"
    fi
    
    echo "Test complete. Results available in $RESULTS_DIR"
}

# 6. 스크립트 실행
main
