#!/usr/bin/env python3
import os
import sys

def fix_symlinks(start_dir):
    count = 0
    # os.walk는 C로 구현되어 있어 디렉토리 탐색 속도가 매우 빠릅니다.
    for root, dirs, files in os.walk(start_dir):
        for filename in files:
            file_path = os.path.join(root, filename)
            
            # 1. 심볼릭 링크인지 확인 (시스템 호출 최소화)
            if os.path.islink(file_path):
                try:
                    # 2. 링크 타겟 읽기
                    target = os.readlink(file_path)
                    
                    # 3. 절대 경로인지 확인 ('/'로 시작)
                    if target.startswith('/'):
                        # 4. 상대 경로 계산 (문자열 연산이라 매우 빠름)
                        # os.path.relpath는 타겟 파일의 존재 여부와 상관없이 경로만 계산합니다.
                        relative_target = os.path.relpath(target, root)
                        
                        # 5. 링크 업데이트
                        # 기존 링크 제거 후 새로 생성 (Atomic한 교체를 위해)
                        os.unlink(file_path)
                        os.symlink(relative_target, file_path)
                        
                        print(f"� 수정됨: {file_path}")
                        print(f"   └─ {target}  ->  {relative_target}")
                        count += 1
                        
                except OSError as e:
                    print(f" 에러 발생 ({file_path}): {e}")

    print("-" * 40)
    print(f" 작업 완료: 총 {count}개의 절대경로 링크를 변경했습니다.")

if __name__ == "__main__":
    # 인자가 없으면 현재 디렉토리(.)
    target_directory = sys.argv[1] if len(sys.argv) > 1 else "."
    
    if not os.path.exists(target_directory):
        print(f"에러: '{target_directory}' 경로를 찾을 수 없습니다.")
        sys.exit(1)

    print(f" 고속 모드로 링크 수정 시작: {target_directory}")
    fix_symlinks(target_directory)