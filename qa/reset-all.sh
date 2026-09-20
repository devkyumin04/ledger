#!/bin/bash
# DB 전체 초기화 + 테스트 계정 재가입
# 사용법: export QA_PASSWORD='비밀번호'  후  sh qa/reset-all.sh
# 전제: 서버 기동 중 (재가입을 API 로 해야 '미분류' E/I 가 자동 생성됨)
#       MySQL root 비밀번호는 실행 중 프롬프트로 입력 (CI 는 QA_DB_* 환경변수 — _lib.sh 상단)

# 서버 주소·비밀번호 확인·DB 접속(qa_mysql)은 _lib.sh 와 같은 것을 쓴다
. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"

# 1. 서버 확인 (DB 를 밀고 나서 서버가 없으면 재가입을 못 해 반쪽 상태가 됨)
if ! curl -s -o /dev/null "$BASE/"; then
  echo "❌ 서버($BASE)가 응답하지 않습니다. 먼저 기동하세요."; exit 1
fi

# 2. DB 초기화
qa_mysql < "$QA_DIR/reset-all.sql" || { echo "❌ DB 초기화 실패"; exit 1; }

# 3. 재가입
signup() { # email nickname
  local res code
  res=$(curl -s -w "\n%{http_code}" -X POST "$BASE/api/users/signup" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$QA_PASSWORD\",\"nickname\":\"$2\"}")
  code=$(echo "$res" | tail -1)
  # 실패하면 응답 본문을 같이 찍는다 — 코드만으론 원인(비번 규칙 등)을 알 수 없다
  if [ "$code" = "201" ] || [ "$code" = "200" ]; then echo "✅ 가입 $1 ($code)"
  else echo "❌ 가입 실패 $1 ($code)  → $(echo "$res" | sed '$d')"; exit 1; fi
}
signup test@test.com     테스트
signup rollback@test.com 롤백

echo "── 완료. 브라우저 토큰은 무효이니 다시 로그인할 것 ──"
