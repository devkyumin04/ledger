-- Refresh 토큰 로테이션 · 재사용 탐지 · 유예 30초 (ADR-055)
--
-- FAMILY_ID        로그인 한 번 = 패밀리 하나(UUID). 재사용이 걸리면 이 값으로 패밀리 전체를 폐기한다
--                  NOT NULL — NULL 이면 WHERE FAMILY_ID = ? 에 안 잡혀 패밀리 폐기를 피해 간다
-- REVOKED_AT       폐기 시각. NULL = 아직 폐기 안 됨. 유예 30초 판정용
--                  폐기할 때 REVOKED_YN 과 같은 UPDATE 에서 채운다 (두 칸이 같은 사실을 말한다)
-- UK_TOKEN_HASH    쿠키 원문 → SHA-256 → 이 칸으로 줄을 찾는다. 해시 하나 = 토큰 한 장
-- IDX_TOKEN_FAMILY 유예 판정("살아 있는 줄 있나") · 패밀리 전체 폐기
--
-- forward-only (ADR-053) — 이전 jar 는 이 테이블을 쓰지 않아서(코드 0건) 롤백해도 그대로 돈다.
-- 그래서 V2 와 달리 NOT NULL 칸을 추가할 수 있다
-- 적용 전 확인 — 로컬 · 운영 모두 0행 (2026-09-25). 줄이 있었다면 NOT NULL 칸에 '' 가 조용히 채워져
-- 서로 다른 로그인이 한 패밀리로 묶인다
ALTER TABLE refresh_tokens
    ADD COLUMN FAMILY_ID  CHAR(36) NOT NULL AFTER TOKEN_NUM,
    ADD COLUMN REVOKED_AT DATETIME NULL     AFTER REVOKED_YN,
    ADD UNIQUE KEY UK_TOKEN_HASH    (TOKEN_HASH),
    ADD KEY        IDX_TOKEN_FAMILY (FAMILY_ID);
