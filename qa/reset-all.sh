#!/bin/bash
# DB 전체 초기화 + 테스트 계정 재가입
# 사용법: export QA_PASSWORD='비밀번호'  후  sh qa/reset-all.sh
# 전제: 서버 기동 중 (재가입을 API 로 해야 '미분류' E/I 가 자동 생성됨)
#       MySQL root 비밀번호는 실행 중 프롬프트로 입력

BASE=http://localhost:8080
QA_PASSWORD="${QA_PASSWORD:?QA_PASSWORD 환경변수가 필요합니다.  예) export QA_PASSWORD='비밀번호'}"
DIR="$(cd "$(dirname "$0")" && pwd)"

# 1. 서버 확인 (DB 를 밀고 나서 서버가 없으면 재가입을 못 해 반쪽 상태가 됨)
if ! curl -s -o /dev/null "$BASE/"; then
  echo "❌ 서버($BASE)가 응답하지 않습니다. 먼저 기동하세요."; exit 1
fi

# 2. DB 초기화
mysql -u root -p ledger_db < "$DIR/reset-all.sql" || { echo "❌ DB 초기화 실패"; exit 1; }

# 3. 재가입
signup() { # email nickname
  local code
  code=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$BASE/api/users/signup" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$QA_PASSWORD\",\"nickname\":\"$2\"}")
  if [ "$code" = "201" ] || [ "$code" = "200" ]; then echo "✅ 가입 $1 ($code)"
  else echo "❌ 가입 실패 $1 ($code)"; exit 1; fi
}
signup test@test.com     테스트
signup rollback@test.com 롤백

echo "── 완료. 브라우저 토큰은 무효이니 다시 로그인할 것 ──"
