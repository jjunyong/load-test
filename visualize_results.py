import sys
import os
#import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns

def create_visualizations(results_dir):
    # 데이터 읽기
    csv_file = os.path.join(results_dir, 'test_summary.csv')
    df = pd.read_csv(csv_file)
    
    # 그래프 스타일 설정
    plt.style.use('seaborn')
    fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 10))
    
    # 1. 동시 사용자 수 vs 성공률
    ax1.plot(df['Concurrent Users'], df['Success Rate'], 'b-o')
    ax1.set_title('Concurrent Users vs Success Rate')
    ax1.set_xlabel('Concurrent Users')
    ax1.set_ylabel('Success Rate (%)')
    ax1.grid(True)
    
    # 2. 동시 사용자 수 vs 응답 시간
    ax2.plot(df['Concurrent Users'], df['Avg Response Time(ms)'], 'g-o', label='Avg')
    ax2.plot(df['Concurrent Users'], df['P95 Response Time(ms)'], 'r-o', label='P95')
    ax2.set_title('Response Times')
    ax2.set_xlabel('Concurrent Users')
    ax2.set_ylabel('Response Time (ms)')
    ax2.legend()
    ax2.grid(True)
    
    # 3. 동시 사용자 수 vs RPS
    ax3.plot(df['Concurrent Users'], df['RPS'], 'p-o')
    ax3.set_title('Concurrent Users vs RPS')
    ax3.set_xlabel('Concurrent Users')
    ax3.set_ylabel('Requests Per Second')
    ax3.grid(True)
    
    # 4. 동시 사용자 수 vs 에러 수
    ax4.plot(df['Concurrent Users'], df['Error Count'], 'r-o')
    ax4.set_title('Concurrent Users vs Errors')
    ax4.set_xlabel('Concurrent Users')
    ax4.set_ylabel('Error Count')
    ax4.grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(results_dir, 'load_test_results.png'))

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python3 visualize_results.py <results_directory>")
        sys.exit(1)
    
    results_dir = sys.argv[1]
    create_visualizations(results_dir)
