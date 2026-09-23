#!/bin/bash
# 마이페이지 — 닉네임 · 비밀번호 변경  (PUT /api/users/me/nickname, PUT /api/users/me/password)
# 사용법: bash qa/test-mypage.sh
# 전제: 서버 기동(최신 코드), export QA_PASSWORD='비밀번호'
#       공용 계정의 비밀번호를 바꾸면 다른 스크립트가 깨진다 — 전용 계정을 매번 새로 만든다
#
# 검사하는 것
#   · 관문 — 무토큰 401 / 누락 400 / 틀림 400 / 맞음 204
#   · 닉네임 — 무토큰 401 / 빈 값 400 / 21자 400 / 20자 200 + 응답·/me 반영 / Mass Assignment(email 끼워넣기) 무시
#   · 비밀번호 — 현재 비번 틀림 400(401 아님) / 새 비번 규칙 위반 400(짧음·특수문자 없음) / 지금과 같은 비번 400 / 204 → 옛 비번 로그인 401, 새 비번 200

. "$(cd "$(dirname "$0")" && pwd)/_lib.sh"
ask_reset

E="qa-mp-$(date +%s)@test.com"
B="{\"email\":\"$E\",\"password\":\"$QA_PASSWORD\",\"nickname\":\"마이QA\"}"
LAST=$(raw POST /api/users/signup "$B"); neednum "$(jnum userNum)" "가입 $E"
TOKEN=$(login "$E"); checktoken "$TOKEN" "$E"

echo "── 0. 관문 (마이페이지 들어가기 전 비밀번호 확인)"
B='{"password":"x"}'
traw 0-a 401 POST /api/users/me/verify-password "$B"
B='{}'
t    0-b 400 POST /api/users/me/verify-password "$B"
B='{"password":"wrong-password-1"}'
t    0-c 400 POST /api/users/me/verify-password "$B"   # 401 이 아니다 — 401 이면 화면이 로그아웃된다
has  0-d "비밀번호가 일치하지 않습니다"
B="{\"password\":\"$QA_PASSWORD\"}"
t    0-e 204 POST /api/users/me/verify-password "$B"

echo "── 1. 닉네임"
B='{"nickname":"새이름"}'
traw 1-a 401 PUT /api/users/me/nickname "$B"
B='{"nickname":"   "}'
t    1-b 400 PUT /api/users/me/nickname "$B"
B='{"nickname":"123456789012345678901"}'
t    1-c 400 PUT /api/users/me/nickname "$B"
B='{"nickname":"12345678901234567890"}'
t    1-d 200 PUT /api/users/me/nickname "$B"
has  1-e '"nickname":"12345678901234567890"'
t    1-f 200 GET /api/users/me
has  1-g '"nickname":"12345678901234567890"'
B='{"nickname":"새이름","email":"hijack@test.com","userNum":1}'
t    1-h 200 PUT /api/users/me/nickname "$B"   # 모르는 필드는 무시된다
has  1-i "\"email\":\"$E\""

echo "── 2. 비밀번호"
NEW='Qa-new-pass-1!'
B="{\"currentPassword\":\"wrong-password-1\",\"newPassword\":\"$NEW\"}"
t    2-a 400 PUT /api/users/me/password "$B"
has  2-b "현재 비밀번호가 일치하지 않습니다"
B="{\"currentPassword\":\"$QA_PASSWORD\",\"newPassword\":\"short1!\"}"
t    2-c 400 PUT /api/users/me/password "$B"
B="{\"currentPassword\":\"$QA_PASSWORD\",\"newPassword\":\"nospecial123\"}"
t    2-d 400 PUT /api/users/me/password "$B"
B="{\"currentPassword\":\"$QA_PASSWORD\"}"
t    2-e 400 PUT /api/users/me/password "$B"
B="{\"currentPassword\":\"$QA_PASSWORD\",\"newPassword\":\"$QA_PASSWORD\"}"
t    2-i 400 PUT /api/users/me/password "$B"   # 지금 비번과 같은 비번으로는 못 바꾼다
has  2-j "현재 비밀번호와 다른 비밀번호"
B="{\"currentPassword\":\"$QA_PASSWORD\",\"newPassword\":\"$NEW\"}"
t    2-f 204 PUT /api/users/me/password "$B"
B="{\"email\":\"$E\",\"password\":\"$QA_PASSWORD\"}"
traw 2-g 401 POST /api/users/login "$B"   # 옛 비번은 끝
B="{\"email\":\"$E\",\"password\":\"$NEW\"}"
traw 2-h 200 POST /api/users/login "$B"

summary
