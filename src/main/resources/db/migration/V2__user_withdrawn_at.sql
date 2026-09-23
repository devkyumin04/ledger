-- 탈퇴 유예 시작 시각 (ADR-052)
-- 탈퇴하면 USER_STATUS 'W' + 이 값을 채우고, 유예 중 로그인(탈퇴 취소)하면 NULL 로 되돌린다.
-- 이 값이 30일 지난 계정은 스케줄러가 물리적으로 삭제한다.
--
-- forward-only (ADR-053) — 컬럼 추가만 하는 변경이라 이전 jar 로 롤백해도 그대로 돈다
-- (옛 코드는 이 컬럼을 모르고, NULL 허용이라 옛 INSERT 도 통과한다)
ALTER TABLE users ADD COLUMN USER_WITHDRAWN_AT DATETIME NULL AFTER USER_STATUS;
