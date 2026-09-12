#!/bin/bash
# 개인 지출/수입 CRUD QA — 정상 / 실수 / 악의적
# 사용법: sh qa/transaction-crud.sh
# 전제: 서버 기동, test@test.com + rollback@test.com
#       비밀번호는 QA_PASSWORD 환경변수로 주입 (application.yml 의 DB_PASSWORD 와 같은 방식)
#       예) export QA_PASSWORD='비밀번호'  후 실행
#
# 주의: 중첩 명령치환 "$(req ... "body")" 은 macOS /bin/sh 에서 body 가 유실된다.
#       반드시 B=... 로 본문을 변수에 담고 t() 에 넘길 것.

BASE=http://localhost:8080
QA_PASSWORD="${QA_PASSWORD:?QA_PASSWORD 환경변수가 필요합니다.  예) export QA_PASSWORD='비밀번호'}"
PASS=0; FAIL=0; LAST=""

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
req() { # method path [body]
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
t() { # label expected method path [body]   → 결과를 LAST 에 보관
  LAST=$(req "$3" "$4" "$5")
  local code=$(echo "$LAST" | tail -1)
  local body=$(echo "$LAST" | sed '$d')
  if [ "$code" = "$2" ]; then PASS=$((PASS+1)); printf "✅ %-5s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-5s expected %s got %s  → %s\n" "$1" "$2" "$code" "$body"; fi
}
traw() { # label expected method path [body]  — 토큰 없이
  LAST=$(raw "$3" "$4" "$5")
  local code=$(echo "$LAST" | tail -1)
  if [ "$code" = "$2" ]; then PASS=$((PASS+1)); printf "✅ %-5s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-5s expected %s got %s\n" "$1" "$2" "$code"; fi
}
has() { # label 기대문자열   — 직전 LAST 검사
  local body=$(echo "$LAST" | sed '$d')
  if echo "$body" | grep -q "$2"; then PASS=$((PASS+1)); printf "✅ %-5s contains %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-5s '%s' 없음  → %s\n" "$1" "$2" "$body"; fi
}
jnum() { echo "$LAST" | sed '$d' | sed "s/.*\"$1\":\([0-9]*\).*/\1/"; }
neednum() {
  case "$1" in ''|*[!0-9]*) echo "❌ 기준 데이터 실패 ($2): $1"; exit 1;; esac
}

TODAY=$(date +%F)
FUTURE=$(date -v+1d +%F 2>/dev/null || date -d "+1 day" +%F)
YEAR=$(date +%Y); MONTH=$(date +%-m)

TOKEN=$(login test@test.com); checktoken "$TOKEN" test@test.com
MAIN_TOKEN=$TOKEN

B='{"categoryName":"QA거래지출","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); CAT_E=$(jnum categoryNum); neednum "$CAT_E" 지출카테고리
B='{"categoryName":"QA거래수입","categoryType":"I"}'
LAST=$(req POST /api/categories "$B"); CAT_I=$(jnum categoryNum); neednum "$CAT_I" 수입카테고리
echo "기준: 지출=$CAT_E 수입=$CAT_I  오늘=$TODAY  조회=$YEAR-$MONTH"; echo

echo "───── 정상 케이스"
B="{\"categoryNum\":$CAT_E,\"transAmount\":12000,\"transDate\":\"$TODAY\",\"transMemo\":\"점심\"}"
t 1 201 POST /api/transactions "$B"
has 1-a '"transType":"E"'; has 1-b '"version":0'; has 1-c '"categoryName":"QA거래지출"'
T1=$(jnum transNum); neednum "$T1" 거래1

B="{\"categoryNum\":$CAT_I,\"transAmount\":3000000,\"transDate\":\"$TODAY\",\"transMemo\":\"월급\"}"
t 2 201 POST /api/transactions "$B"; has 2-a '"transType":"I"'; T2=$(jnum transNum)

B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\"}"
t 3 201 POST /api/transactions "$B"

B="{\"categoryNum\":$CAT_E,\"transAmount\":1,\"transDate\":\"$TODAY\",\"transMemo\":\"오늘경계\"}"
t 4 201 POST /api/transactions "$B"

t 5 200 GET "/api/transactions?year=$YEAR&month=$MONTH"
has 5-a '"categoryEmoji"'; has 5-b '"categoryNum"'
t 6 200 GET "/api/transactions?year=1999&month=1"

B="{\"categoryNum\":$CAT_E,\"transAmount\":15000,\"transDate\":\"$TODAY\",\"transMemo\":\"점심수정\"}"
t 7 200 PUT "/api/transactions/$T1?version=0" "$B"; has 7-a '"version":1'

B="{\"categoryNum\":$CAT_E,\"transAmount\":16000,\"transDate\":\"$TODAY\",\"transMemo\":\"연속수정\"}"
t 8 200 PUT "/api/transactions/$T1?version=1" "$B"; has 8-a '"version":2'

B="{\"categoryNum\":$CAT_I,\"transAmount\":16000,\"transDate\":\"$TODAY\",\"transMemo\":\"타입변경\"}"
t 9 200 PUT "/api/transactions/$T1?version=2" "$B"; has 9-a '"transType":"I"'

t 10 204 DELETE "/api/transactions/$T2?version=0"
LAST=$(req GET "/api/transactions?year=$YEAR&month=$MONTH")
if echo "$LAST" | sed '$d' | grep -q "\"transNum\":$T2,"; then
  FAIL=$((FAIL+1)); printf "❌ %-5s 삭제 건이 목록에 남음\n" 11
else PASS=$((PASS+1)); printf "✅ %-5s 삭제 건 목록에서 제외\n" 11; fi
echo

echo "───── 실수 케이스 (입력값)"
B="{\"categoryNum\":$CAT_E,\"transAmount\":0,\"transDate\":\"$TODAY\"}";            t 12 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":-5000,\"transDate\":\"$TODAY\"}";        t 13 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":1000000000001,\"transDate\":\"$TODAY\"}";t 14 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transDate\":\"$TODAY\"}";                              t 15-a 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000}";                                  t 15-b 400 POST /api/transactions "$B"
B="{\"transAmount\":5000,\"transDate\":\"$TODAY\"}";                                t 15-c 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$FUTURE\"}";        t 16 400 POST /api/transactions "$B"
LONG=$(printf 'a%.0s' $(seq 1 101))
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\",\"transMemo\":\"$LONG\"}"; t 17 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"2026-13-45\"}";     t 18 400 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":";                                       t 19 400 POST /api/transactions "$B"
echo

echo "───── 실수 케이스 (존재하지 않음 / 파라미터)"
B="{\"categoryNum\":999999,\"transAmount\":5000,\"transDate\":\"$TODAY\"}";         t 20 404 POST /api/transactions "$B"
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\"}"
t 21-a 404 PUT "/api/transactions/999999?version=0" "$B"
t 21-b 404 DELETE "/api/transactions/999999?version=0"
t 22-a 400 GET "/api/transactions?month=$MONTH"
t 22-b 400 GET "/api/transactions?year=$YEAR"
t 23-a 400 PUT "/api/transactions/$T1" "$B"
t 23-b 400 DELETE "/api/transactions/$T1"

B="{\"categoryNum\":$CAT_E,\"transAmount\":7777,\"transDate\":\"2025-12-15\",\"transMemo\":\"12월경계\"}"
LAST=$(req POST /api/transactions "$B"); T_DEC=$(jnum transNum)
LAST=$(req GET "/api/transactions?year=2025&month=12")
if echo "$LAST" | sed '$d' | grep -q '"transAmount":7777'; then
  PASS=$((PASS+1)); printf "✅ %-5s 12월 조회 정상\n" 24-a
else FAIL=$((FAIL+1)); printf "❌ %-5s 12월 조회에 안 나옴\n" 24-a; fi
LAST=$(req GET "/api/transactions?year=2025&month=1")
if echo "$LAST" | sed '$d' | grep -q '"transAmount":7777'; then
  FAIL=$((FAIL+1)); printf "❌ %-5s 1월에 12월 건이 섞임\n" 24-b
else PASS=$((PASS+1)); printf "✅ %-5s 월 범위 정확\n" 24-b; fi
echo

echo "───── 악의적 케이스"
traw 25-a 401 GET "/api/transactions?year=$YEAR&month=$MONTH"
B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\"}"
traw 25-b 401 POST /api/transactions "$B"

TOKEN=$(login rollback@test.com); checktoken "$TOKEN" rollback@test.com
B='{"categoryName":"QA타인지출","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); OTHER_CAT=$(jnum categoryNum); neednum "$OTHER_CAT" 타인카테고리
B="{\"categoryNum\":$OTHER_CAT,\"transAmount\":9999,\"transDate\":\"$TODAY\"}"
LAST=$(req POST /api/transactions "$B"); OTHER_TRANS=$(jnum transNum); neednum "$OTHER_TRANS" 타인거래
TOKEN=$MAIN_TOKEN

B="{\"categoryNum\":$CAT_E,\"transAmount\":1,\"transDate\":\"$TODAY\"}"
t 26-a 403 PUT "/api/transactions/$OTHER_TRANS?version=0" "$B"
t 26-b 403 DELETE "/api/transactions/$OTHER_TRANS?version=0"

B="{\"categoryNum\":$OTHER_CAT,\"transAmount\":5000,\"transDate\":\"$TODAY\"}"
t 27 403 POST /api/transactions "$B"
t 28 403 PUT "/api/transactions/$T1?version=3" "$B"

B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\"}"
t 29-a 404 PUT "/api/transactions/$T2?version=1" "$B"
t 29-b 404 DELETE "/api/transactions/$T2?version=1"

t 30-a 409 PUT "/api/transactions/$T1?version=0" "$B"
t 30-b 409 DELETE "/api/transactions/$T_DEC?version=99"

B="{\"categoryNum\":$CAT_E,\"transAmount\":5000,\"transDate\":\"$TODAY\",\"userNum\":99999,\"transType\":\"I\",\"version\":77}"
t 31 201 POST /api/transactions "$B"
has 31-a '"transType":"E"'; has 31-b '"version":0'
echo

echo "═════════════════════════════"
printf "PASS %d / FAIL %d\n" $PASS $FAIL
