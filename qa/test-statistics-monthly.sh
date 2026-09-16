#!/bin/bash
# 개인 통계 — 6개월 추이 QA  (GET /api/statistics/monthly?year=&month=)
# 사용법: sh qa/test-statistics-monthly.sh
# 전제: 서버 기동(최신 코드로 재시작), test@test.com + rollback@test.com, export QA_PASSWORD='비밀번호'
#
# 데이터는 2020~2021년 과거 날짜에 넣는다. 오늘 날짜에 넣으면 다른 QA·손 데이터와 섞여
# 합계를 정확히 비교할 수 없기 때문. 시작 전 해당 기간이 비어 있는지 먼저 확인한다.
#
# 넣는 데이터 (test 유저)
#   2020-06-30  지출    7,000   ← 범위 밖(시작 전날). 제외돼야 함
#   2020-07-01  수입 3,000,000   ← 시작 경계(포함)
#   2020-07-15  지출   12,000
#   2020-08-10  지출    5,000   ← 지출만 있는 달 → 수입 0 (ELSE 0)
#   2020-09     없음            ← 빈 달 → 0,0,0 채움
#   2020-10-05  수입  100,000   ← 수입만 있는 달
#   2020-11-20  지출   50,000   → 바로 삭제 (소프트 딜리트 제외)
#   2020-12-31  지출    1,000 / 수입 500  ← 끝 경계(포함), 음수 잔액
#   2021-01-01  지출    2,000   ← 범위 밖(끝 다음날). 12월 조회에선 제외
#   (rollback 유저) 2020-10-05 지출 9,999  ← 사용자 격리

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ask_reset

M=/api/statistics/monthly

# 응답에 나온 yearMonth 순서를 한 줄로
months() { echo "$LAST" | sed '$d' | grep -o '"yearMonth":"[0-9-]*"' | sed 's/"yearMonth":"//; s/"//' | tr '\n' ' ' | sed 's/ $//'; }
eq() { # label 기대값 실제값
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf "✅ %-6s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-6s expected [%s] got [%s]\n" "$1" "$2" "$3"; fi
}
row() { # yearMonth income expense balance → 응답 속 한 원소 문자열
  echo "{\"yearMonth\":\"$1\",\"totalIncome\":$2,\"totalExpense\":$3,\"balance\":$4}"
}

TOKEN=$(login test@test.com); checktoken "$TOKEN" test@test.com
MAIN_TOKEN=$TOKEN

# ── 사전 확인: 2020-06 ~ 2021-02 가 비어 있어야 기대값이 맞는다
LAST=$(req GET "$M?year=2020&month=12"); A=$(echo "$LAST" | sed '$d')
LAST=$(req GET "$M?year=2021&month=2");  B2=$(echo "$LAST" | sed '$d')
if echo "$A$B2" | grep -q '"totalIncome":[1-9]\|"totalExpense":[1-9]'; then
  echo "❌ 2020~2021 기간에 이미 거래가 있습니다. 초기화(y) 후 다시 실행하세요."; exit 1
fi

B='{"categoryName":"QA추이지출","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); CAT_E=$(jnum categoryNum); neednum "$CAT_E" 지출카테고리
B='{"categoryName":"QA추이수입","categoryType":"I"}'
LAST=$(req POST /api/categories "$B"); CAT_I=$(jnum categoryNum); neednum "$CAT_I" 수입카테고리

add() { # categoryNum amount date
  B="{\"categoryNum\":$1,\"transAmount\":$2,\"transDate\":\"$3\"}"
  LAST=$(req POST /api/transactions "$B"); neednum "$(jnum transNum)" "거래 $3"
}
add $CAT_E 7000    2020-06-30
add $CAT_I 3000000 2020-07-01
add $CAT_E 12000   2020-07-15
add $CAT_E 5000    2020-08-10
add $CAT_I 100000  2020-10-05
add $CAT_E 50000   2020-11-20; DEL=$(jnum transNum)
LAST=$(req DELETE "/api/transactions/$DEL?version=0")
add $CAT_E 1000    2020-12-31
add $CAT_I 500     2020-12-31
add $CAT_E 2000    2021-01-01

TOKEN=$(login rollback@test.com); checktoken "$TOKEN" rollback@test.com
B='{"categoryName":"QA추이타인","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); OTHER_CAT=$(jnum categoryNum); neednum "$OTHER_CAT" 타인카테고리
add $OTHER_CAT 9999 2020-10-05
TOKEN=$MAIN_TOKEN
echo "기준 데이터 입력 완료 (삭제한 거래=$DEL)"; echo

echo "───── 정상: 2020-12 조회"
t 1 200 GET "$M?year=2020&month=12"
eq 1-a "2020-07 2020-08 2020-09 2020-10 2020-11 2020-12" "$(months)"     # 6개, 오름차순, 빈 달 포함
has 1-b "$(row 2020-07 3000000 12000 2988000)"   # 시작 경계 포함 + 6/30 제외
has 1-c "$(row 2020-08 0 5000 -5000)"            # 지출만 → 수입 0
has 1-d "$(row 2020-09 0 0 0)"                   # 빈 달 채움
has 1-e "$(row 2020-10 100000 0 100000)"         # 수입만 + 타인 9,999 안 섞임
has 1-f "$(row 2020-11 0 0 0)"                   # 삭제 거래 제외
has 1-g "$(row 2020-12 500 1000 -500)"           # 끝 경계 포함 + 1/1 제외, 음수 잔액
echo

echo "───── 경계: 연도 넘김 2021-02 조회"
t 2 200 GET "$M?year=2021&month=2"
eq 2-a "2020-09 2020-10 2020-11 2020-12 2021-01 2021-02" "$(months)"
has 2-b "$(row 2021-01 0 2000 -2000)"
has 2-c "$(row 2021-02 0 0 0)"
echo

echo "───── 경계: 거래 전혀 없는 기간"
t 3 200 GET "$M?year=1999&month=6"
eq 3-a "1999-01 1999-02 1999-03 1999-04 1999-05 1999-06" "$(months)"
has 3-b "$(row 1999-06 0 0 0)"
echo

echo "───── 대조: 카테고리 통계와 같은 합계인가"
t 4 200 GET "/api/statistics/expense?year=2020&month=7"
has 4-a '"amount":12000'
t 4-b 200 GET "/api/statistics/income?year=2020&month=12"
has 4-c '"amount":500'
echo

echo "───── 실수 / 악의적"
t 5-a 400 GET "$M?year=2020"
t 5-b 400 GET "$M?month=12"
t 5-c 400 GET "$M?year=2020&month=abc"
traw 6 401 GET "$M?year=2020&month=12"
echo

echo "───── 기록만 (판정 안 함 — 결과 보고 로드맵에 적을지 결정)"
LAST=$(req GET "$M?year=2020&month=13"); echo "month=13 → $(echo "$LAST" | tail -1)"
LAST=$(req GET "$M?year=2020&month=0");  echo "month=0  → $(echo "$LAST" | tail -1)"
echo

summary
