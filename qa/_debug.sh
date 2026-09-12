#!/bin/bash
BASE=http://localhost:8080
echo "───── 1. 로그인 원본 응답"
RAW=$(curl -s -X POST $BASE/api/users/login -H "Content-Type: application/json" \
  -d '{"email":"test@test.com","password":"abc1234!"}')
echo "$RAW"
echo
echo "───── 2. sed 로 뽑은 토큰"
TOKEN=$(echo "$RAW" | sed 's/.*"accessToken":"\([^"]*\)".*/\1/')
echo "길이: ${#TOKEN}"
echo "앞 40자: ${TOKEN:0:40}"
echo "점 개수(정상 JWT=2): $(echo "$TOKEN" | tr -cd '.' | wc -c)"
echo
echo "───── 3. 그 토큰으로 카테고리 조회"
curl -s -i -X GET $BASE/api/categories -H "Authorization: Bearer $TOKEN" | head -12
echo
echo "───── 4. 그 토큰으로 카테고리 등록"
curl -s -i -X POST $BASE/api/categories -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"categoryName":"디버그","categoryType":"E"}' | head -12
