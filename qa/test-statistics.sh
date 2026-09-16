#!/bin/bash
# 개인 통계 — 최종 API QA  (GET /api/statistics?year=&month=)
# 사용법: sh qa/test-statistics.sh
# 전제: 서버 기동(최신 코드로 재시작), test@test.com + rollback@test.com, export QA_PASSWORD='비밀번호'
#
# 검사하는 것
#   · 요약 4개(totalIncome / totalExpense / balance / expenseRatio) 가 봉투 목록·추이와 일치하는가
#   · 소비율 — 수입 0 이면 null, 소수 1자리 HALF_UP (66.666 → 66.7)
#   · 봉투 — 대분류 직접 거래 + 소분류가 한 봉투에 묶이고 비율이 부모 대비인가
#   · 빈 목록은 [] 로 나가는가 (지출만 있는 달의 incomeList 등)
#   · month 범위 검증 400 (@Min/@Max + HandlerMethodValidationException 핸들러)
#
# 데이터는 2020 년 세트(옛 test-statistics-monthly.sh 의 것을 흡수) + 2021-03 반올림·소분류 세트.
# 시작 전 해당 기간이 비어 있는지 먼저 확인한다 (초기화 y 권장).
#
#   2020-07  수입 3,000,000 / 지출 12,000          → 소비율 0.4
#   2020-08  지출 5,000 만                         → 수입 0 → 소비율 null, incomeList []
#   2020-10  수입 100,000 만 (+ 타인 지출 9,999)   → 지출 0 → 소비율 0.0, expenseList []
#   2020-11  지출 50,000 → 삭제                    → 전부 0
#   2020-12  수입 500 / 지출 1,000                 → 소비율 200.0, 잔액 -500
#   2021-03  수입 3,000 / 지출 1,500(대분류 직접) + 500(소분류)
#                                                  → 소비율 66.7(HALF_UP), 봉투 2,000 = 직접 75.0 + 소분류 25.0

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ask_reset

S=/api/statistics

months() { echo "$LAST" | sed '$d' | grep -o '"yearMonth":"[0-9-]*"' | sed 's/"yearMonth":"//; s/"//' | tr '\n' ' ' | sed 's/ $//'; }
eq() { # label 기대값 실제값
  if [ "$2" = "$3" ]; then PASS=$((PASS+1)); printf "✅ %-6s %s\n" "$1" "$2"
  else FAIL=$((FAIL+1)); printf "❌ %-6s expected [%s] got [%s]\n" "$1" "$2" "$3"; fi
}
row() { echo "{\"yearMonth\":\"$1\",\"totalIncome\":$2,\"totalExpense\":$3,\"balance\":$4}"; }
head4() { # income expense balance ratio → 응답 앞부분 (필드 순서 = DTO 순서)
  echo "{\"totalIncome\":$1,\"totalExpense\":$2,\"balance\":$3,\"expenseRatio\":$4"
}

TOKEN=$(login test@test.com); checktoken "$TOKEN" test@test.com
MAIN_TOKEN=$TOKEN

# ── 사전 확인: 2020-06 ~ 2021-03 이 비어 있어야 기대값이 맞는다
LAST=$(req GET "$S?year=2020&month=12"); A=$(echo "$LAST" | sed '$d')
LAST=$(req GET "$S?year=2021&month=3");  B2=$(echo "$LAST" | sed '$d')
if echo "$A$B2" | grep -q '"totalIncome":[1-9]\|"totalExpense":[1-9]'; then
  echo "❌ 2020~2021 기간에 이미 거래가 있습니다. 초기화(y) 후 다시 실행하세요."; exit 1
fi

B='{"categoryName":"QA통계지출","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); CAT_E=$(jnum categoryNum); neednum "$CAT_E" 지출대분류
B="{\"categoryName\":\"QA통계소분류\",\"categoryType\":\"E\",\"parentCategoryNum\":$CAT_E}"
LAST=$(req POST /api/categories "$B"); CAT_SUB=$(jnum categoryNum); neednum "$CAT_SUB" 지출소분류
B='{"categoryName":"QA통계수입","categoryType":"I"}'
LAST=$(req POST /api/categories "$B"); CAT_I=$(jnum categoryNum); neednum "$CAT_I" 수입카테고리

add() { # categoryNum amount date
  B="{\"categoryNum\":$1,\"transAmount\":$2,\"transDate\":\"$3\"}"
  LAST=$(req POST /api/transactions "$B"); neednum "$(jnum transNum)" "거래 $3"
}
add $CAT_E   7000    2020-06-30
add $CAT_I   3000000 2020-07-01
add $CAT_E   12000   2020-07-15
add $CAT_E   5000    2020-08-10
add $CAT_I   100000  2020-10-05
add $CAT_E   50000   2020-11-20; DEL=$(jnum transNum)
LAST=$(req DELETE "/api/transactions/$DEL?version=0")
add $CAT_E   1000    2020-12-31
add $CAT_I   500     2020-12-31
add $CAT_E   2000    2021-01-01
add $CAT_I   3000    2021-03-10
add $CAT_E   1500    2021-03-11
add $CAT_SUB 500     2021-03-12

TOKEN=$(login rollback@test.com); checktoken "$TOKEN" rollback@test.com
B='{"categoryName":"QA통계타인","categoryType":"E"}'
LAST=$(req POST /api/categories "$B"); OTHER_CAT=$(jnum categoryNum); neednum "$OTHER_CAT" 타인카테고리
add $OTHER_CAT 9999 2020-10-05
TOKEN=$MAIN_TOKEN
echo "기준 데이터 입력 완료 (삭제한 거래=$DEL)"; echo

echo "───── 정상: 2020-12 — 요약·봉투·추이가 한 응답에"
t 1 200 GET "$S?year=2020&month=12"
has 1-a "$(head4 500 1000 -500 200.0)"                         # 요약 4개, 소비율 200.0
has 1-b "\"categoryNum\":$CAT_E,\"categoryName\":\"QA통계지출\",\"categoryEmoji\":null,\"amount\":1000,\"ratio\":100.0"
has 1-c "\"categoryNum\":$CAT_I,\"categoryName\":\"QA통계수입\",\"categoryEmoji\":null,\"amount\":500,\"ratio\":100.0"
eq  1-d "2020-07 2020-08 2020-09 2020-10 2020-11 2020-12" "$(months)"   # 추이 6개
has 1-e "$(row 2020-12 500 1000 -500)"                          # 추이 마지막 = 요약과 같은 값 (일관성)
has 1-f "$(row 2020-11 0 0 0)"                                  # 삭제 거래 제외
has 1-g "$(row 2020-07 3000000 12000 2988000)"                  # 시작 경계 포함 + 6/30 제외
has 1-h "$(row 2020-09 0 0 0)"                                  # 빈 달 채움
echo

echo "───── 경계: 수입 0 (2020-08) — 소비율 null, 수입 목록 빈 배열"
t 2 200 GET "$S?year=2020&month=8"
has 2-a "$(head4 0 5000 -5000 null)"
has 2-b '"incomeList":\[\]'
echo

echo "───── 경계: 지출 0 (2020-10) — 소비율 0.0, 지출 목록 빈 배열, 타인 9,999 안 섞임"
t 3 200 GET "$S?year=2020&month=10"
has 3-a "$(head4 100000 0 100000 0.0)"
has 3-b '"expenseList":\[\]'
echo

echo "───── 경계: 거래 전혀 없는 달 (1999-06) — 전부 0 / null / []"
t 4 200 GET "$S?year=1999&month=6"
has 4-a "$(head4 0 0 0 null)"
has 4-b '"expenseList":\[\],"incomeList":\[\]'
eq  4-c "1999-01 1999-02 1999-03 1999-04 1999-05 1999-06" "$(months)"
echo

echo "───── 소수점: 2020-07 소비율 0.4 / 2021-03 66.7(HALF_UP) + 봉투 안 소분류 비율"
t 5 200 GET "$S?year=2020&month=7"
has 5-a "$(head4 3000000 12000 2988000 0.4)"
t 5-b 200 GET "$S?year=2021&month=3"
has 5-c "$(head4 3000 2000 1000 66.7)"
has 5-d "\"categoryNum\":$CAT_E,\"categoryName\":\"QA통계지출\",\"categoryEmoji\":null,\"amount\":2000,\"ratio\":100.0"   # 봉투 = 직접 + 소분류
has 5-e "\"categoryNum\":$CAT_E,\"categoryName\":\"QA통계지출\",\"categoryEmoji\":null,\"amount\":1500,\"ratio\":75.0"    # 직접 거래 줄 (부모 대비)
has 5-f "\"categoryNum\":$CAT_SUB,\"categoryName\":\"QA통계소분류\",\"categoryEmoji\":null,\"amount\":500,\"ratio\":25.0"
eq  5-g "2020-10 2020-11 2020-12 2021-01 2021-02 2021-03" "$(months)"   # 연도 넘김
has 5-h "$(row 2021-01 0 2000 -2000)"                           # 12월 조회 땐 제외됐던 1/1 이 여기선 포함
has 5-i "$(row 2021-02 0 0 0)"
echo

echo "───── 실수: month 범위 (A안 — @Min/@Max → 400)"
t 6-a 400 GET "$S?year=2020&month=13"
has 6-b "허용 범위"
t 6-c 400 GET "$S?year=2020&month=0"
t 6-d 200 GET "$S?year=2020&month=1"        # 하한 경계 통과
t 6-e 400 GET "$S?year=2020&month=-1"
echo

echo "───── 실수 / 악의적: 누락·형식·권한"
t 7-a 400 GET "$S?year=2020"
t 7-b 400 GET "$S?month=12"
t 7-c 400 GET "$S?year=2020&month=abc"
traw 8 401 GET "$S?year=2020&month=12"
echo

summary
