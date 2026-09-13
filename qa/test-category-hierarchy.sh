#!/bin/bash
# 카테고리 부모 검증 / 하위 삭제 거부 / 로그인 상태 QA
# 사용법: sh qa/test-category-hierarchy.sh
# 전제: test@test.com, rollback@test.com 두 계정 존재
#       비밀번호는 QA_PASSWORD 환경변수로 주입
#       예) export QA_PASSWORD='비밀번호'  후 실행

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ask_reset

TOKEN=$(login test@test.com)
[ -z "$TOKEN" ] && { echo "로그인 실패 (test@test.com)"; exit 1; }

# 기준 데이터: 미분류 E, 대분류 하나 생성
E_DEF=$(req GET /api/categories | sed '$d' | grep -o '"categoryNum":[0-9]*,"categoryName":"미분류","categoryEmoji":null,"categoryType":"E"' | head -1 | grep -o '[0-9]*' | head -1)
R=$(req POST /api/categories '{"categoryName":"QA대분류","categoryType":"E"}'); BIG=$(num "$R")
echo "기준: 미분류E=$E_DEF, 대분류=$BIG"
echo "----- 4. 부모 검증"

R=$(req POST /api/categories '{"categoryName":"QA카페","categoryType":"E","parentCategoryNum":'$BIG'}'); check A 201 "$R"; CAFE=$(num "$R")
check B 400 "$(req POST /api/categories '{"categoryName":"QA월급","categoryType":"I","parentCategoryNum":'$BIG'}')"
check C 400 "$(req POST /api/categories '{"categoryName":"QA스벅","categoryType":"E","parentCategoryNum":'$CAFE'}')"
check D 404 "$(req POST /api/categories '{"categoryName":"x","categoryType":"E","parentCategoryNum":99999}')"
check E 400 "$(req POST /api/categories '{"categoryName":"x","categoryType":"E","parentCategoryNum":'$E_DEF'}')"

TOKEN2=$(login rollback@test.com)
OTHER=$(TOKEN=$TOKEN2 req GET /api/categories | sed '$d' | grep -o '"categoryNum":[0-9]*' | head -1 | tr -dc 0-9)
check F 403 "$(req POST /api/categories '{"categoryName":"x","categoryType":"E","parentCategoryNum":'$OTHER'}')"

check G 400 "$(req PUT /api/categories/$BIG '{"categoryName":"QA대분류","categoryType":"E","parentCategoryNum":'$BIG'}')"
R=$(req POST /api/categories '{"categoryName":"QA교통","categoryType":"E"}'); TRANS=$(num "$R")
check H 400 "$(req PUT /api/categories/$BIG '{"categoryName":"QA대분류","categoryType":"E","parentCategoryNum":'$TRANS'}')"
check I 200 "$(req PUT /api/categories/$CAFE '{"categoryName":"QA카페","categoryType":"E","parentCategoryNum":'$TRANS'}')"

echo "----- 9. 하위 있으면 삭제 거부"
check J 400 "$(req DELETE /api/categories/$TRANS)"
check K 204 "$(req DELETE /api/categories/$CAFE)"
check L 204 "$(req DELETE /api/categories/$TRANS)"

echo "----- 정리"
req DELETE /api/categories/$BIG > /dev/null

summary
echo "(10번 로그인 STATUS는 DB에서 수동 확인: rollback 계정 user_last_login_at 갱신됐는지, status='W'로 바꾸고 로그인 401인지)"
