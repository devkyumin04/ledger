-- QA 데이터 정리
-- USERS 는 남기고, 거래 전체 + 사용자가 만든 카테고리만 삭제한다.
--
-- 사용법:
--   mysql -u root -p <스키마명> < qa/reset-data.sql
--
-- 주의: '미분류'(is_default_yn = 'Y')는 삭제하지 않는다.
--       가입 시 자동 생성되는 기본 카테고리라, 지우면
--       거래 등록과 카테고리 삭제 이관이 전부 깨진다.

-- 1) 거래 전체 삭제 — 카테고리를 참조(FK)하므로 반드시 먼저
DELETE FROM personal_transactions;
ALTER TABLE personal_transactions AUTO_INCREMENT = 1;

-- 2) 사용자 생성 카테고리만 삭제 ('미분류' 유지)
DELETE FROM personal_categories WHERE is_default_yn = 'N';

-- 3) 결과 확인
SELECT '── 남은 카테고리 ──' AS '';
SELECT category_num, user_num, category_name, category_type, is_default_yn
FROM personal_categories ORDER BY user_num, category_num;

SELECT '── 남은 거래 ──' AS '';
SELECT COUNT(*) AS 거래건수 FROM personal_transactions;

SELECT '── 유저 ──' AS '';
SELECT user_num, user_email, user_nickname, user_status FROM users;
