#!/bin/bash
# QA 스크립트 공통 헬퍼. 각 스크립트 상단에서 아래 한 줄로 불러온다.
#   . "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
#
# 담고 있는 것: 서버 주소, 비밀번호 확인, PASS/FAIL 카운터,
#               로그인·요청·판정 헬퍼, 시작 시 데이터 초기화 확인
#
# 주의: 중첩 명령치환 "$(req ... "body")" 은 macOS /bin/sh 에서 body 가 유실된다.
#       본문은 B=... 변수에 담고 t() 에 넘길 것. (트러블슈팅 8)

BASE=http://localhost:8080
QA_PASSWORD="${QA_PASSWORD:?QA_PASSWORD 환경변수가 필요합니다.  예) export QA_PASSWORD='비밀번호'}"
QA_DIR="$(cd "$(dirname "$0")" && pwd)"
PASS=0; FAIL=0; LAST=""

# ── 시작 시 초기화 여부를 묻는다 ──────────────────────────────
# 항상 자동으로 밀면 화면 개발 중 손으로 넣은 데이터가 매번 날아가고,
# 반대로 안 밀면 QA 카테고리가 계속 쌓인다. 그래서 그때그때 고르게 한다.
# (유저와 '미분류'는 reset-data.sql 이 남기므로 재가입은 필요 없다)
ask_reset() {
  printf "기존 거래·카테고리를 지우고 시작할까요? (y/N) "
  read ANS
  case "$ANS" in
    [yY]*)
      mysql -u root -p ledger_db < "$QA_DIR/reset-data.sql" || { echo "❌ 초기화 실패"; exit 1; }
      echo ;;
    *) echo "→ 기존 데이터 유지"; echo ;;
  esac
}

# ── 로그인 ────────────────────────────────────────────────
login() {
  curl -s -X POST $BASE/api/users/login -H "Content-Type: application/json" \
    -d "{\"email\":\"$1\",\"password\":\"$QA_PASSWORD\"}" | sed 's/.*"accessToken":"\([^"]*\)".*/\1/'
}
checktoken() {
  local dots=$(echo "$1" | tr -cd '.' | wc -c | tr -d ' ')
  if [ -z "$1" ] || [ "$dots" != "2" ]; then
    echo "❌ 로그인 실패 ($2)"; echo "   응답: $1"
    echo "   → 계정 존재 여부와 QA_PASSWORD 값을 확인"; exit 1
  fi
}

# ── 요청 ──────────────────────────────────────────────────
req() { # method path [body]  → body\ncode
  if [ -n "$3" ]; then
    curl -s -w "\n%{http_code}" -X "$1" "$BASE$2" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" -d "$3"
  else
    curl -s -w "\n%{http_code}" -X "$1" "$BASE$2" -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json"
  fi
}
raw() { # 토큰 없이
  if [ -n "$3" ]; then
    curl -s -w "\n%{http_code}" -X "$1" "$BASE$2" -H "Content-Type: application/json" -d "$3"
  else
    curl -s -w "\n%{http_code}" -X "$1" "$BASE$2" -H "Content-Type: application/json"
  fi
}

# ── 판정 ──────────────────────────────────────────────────
# t/traw : 요청과 판정을 한 번에 (중첩 치환 없음). 결과는 LAST 에 보관
# check  : 이미 받아둔 응답을 판정 (test-category-hierarchy.sh 방식)
t() { # label expected method path [body]
  LAST=$(req "$3" "$4" "$5")
  local code=$(echo "$LAST" | tail -1)
  local body=$(echo "$LAST" | sed '$d')
  if [ "$code" = "$2" ]; then PASS=$((PASS+1)); printf "✅ %-6s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-6s expected %s got %s  → %s\n" "$1" "$2" "$code" "$body"; fi
}
traw() { # label expected method path [body]  — 토큰 없이
  LAST=$(raw "$3" "$4" "$5")
  local code=$(echo "$LAST" | tail -1)
  if [ "$code" = "$2" ]; then PASS=$((PASS+1)); printf "✅ %-6s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-6s expected %s got %s\n" "$1" "$2" "$code"; fi
}
check() { # label expected 응답
  local code=$(echo "$3" | tail -1)
  local body=$(echo "$3" | sed '$d')
  if [ "$code" = "$2" ]; then PASS=$((PASS+1)); printf "✅ %-4s %s [%s]\n" "$1" "$2" "$code"
  else FAIL=$((FAIL+1)); printf "❌ %-4s expected %s got %s  → %s\n" "$1" "$2" "$code" "$body"; fi
}
has() { # label 기대문자열   — 직전 LAST 검사
  local body=$(echo "$LAST" | sed '$d')
  if echo "$body" | grep -q "$2"; then PASS=$((PASS+1)); printf "✅ %-6s contains %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-6s '%s' 없음  → %s\n" "$1" "$2" "$body"; fi
}

# ── 값 꺼내기 ─────────────────────────────────────────────
jnum() { echo "$LAST" | sed '$d' | sed "s/.*\"$1\":\([0-9]*\).*/\1/"; }   # LAST 에서 필드명으로
num() { echo "$1" | sed '$d' | sed 's/.*"categoryNum":\([0-9]*\).*/\1/'; } # 넘겨받은 응답에서 categoryNum
neednum() {
  case "$1" in ''|*[!0-9]*) echo "❌ 기준 데이터 실패 ($2): $1"; exit 1;; esac
}

summary() {
  echo "═════════════════════════════"
  printf "PASS %d / FAIL %d\n" $PASS $FAIL
}
