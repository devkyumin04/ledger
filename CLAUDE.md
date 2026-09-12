# Ledger V3.0

AI 영수증 인식 및 지도 기반 개인·공동 가계부. 24시간 상시 운영 실서비스를 목표로 개발 중.

상세 문서는 `docs/` 참조:

| 문서 | 내용 |
|---|---|
| [기획서](docs/기획서.md) | 기능 명세, AI 파이프라인, 보안 정책, 비즈니스 룰, 스프린트 계획 |
| [테이블 설계](docs/테이블설계.md) | 18개 테이블 물리 설계 (컬럼·타입·제약·인덱스) |
| [설계 결정 기록](docs/decisions.md) | 왜 그렇게 결정했는지 (ADR) |
| [트러블슈팅](docs/트러블슈팅.md) | 겪은 문제와 해결 과정 |
| [진행 상황](docs/진행상황.md) | 스프린트별 완료·예정 항목 |
| 로컬환경.md (git 제외) | 테스트 계정 등 커밋하면 안 되는 로컬 메모. `.gitignore` 등록됨 |

---

## 기술 스택

- **백엔드** — Java 17, Spring Boot 4.0.8, MyBatis, MySQL, Flyway, Spring Security, JWT(jjwt), Lombok
- **프론트** — Vanilla JS(ES6+), HTML5/CSS3, Fetch API, PWA 예정
- **AI** — 네이버 Clova 일반 OCR + 로컬 LLM(Ollama) + 한국어 문장 임베딩
- **지도** — 카카오맵 API
- **인프라** — AWS EC2(t3.medium) 단일 인스턴스에 Spring Boot + MySQL + 임베딩 모델 + Redis, S3, Nginx, GitHub Actions

패키지 루트: `com.kyumin.ledger`

---

## 프로젝트 규칙

### 데이터 무결성

- **소프트 딜리트** — `USE_YN` CHAR(1), 기본 `'Y'`. 조회·수정 `WHERE`에 `use_yn = 'Y'` 필수
- **생성일시** — `CREATED_AT` DATETIME DEFAULT CURRENT_TIMESTAMP
- **낙관적 락** — `VERSION` INT. 수정·삭제 시 `SET`에 `version = version + 1`, `WHERE`에 `version = #{version}` 조건. affected rows가 0이면 충돌 → 409
- 금액 0/음수는 화면·서버 이중 검증. DB에도 CHECK 제약
- 조회 조건에 `USER_NUM` 강제 (사용자 간 데이터 격리)

### MyBatis

- `#{}` 바인딩만 사용. `${}` 금지 (SQL 인젝션)
- 매퍼 파라미터가 2개 이상이면 `@Param` 필수 (`-parameters` 옵션 의존 회피)
- `map-underscore-to-camel-case: true` 활성화됨
- 반환 타입: `WHERE` 조건 때문에 0행이 나올 수 있고 그걸 구분해야 하면 `int`, 아니면 `void`

### 마이그레이션

- DDL은 `V1__init_schema.sql` 하나로 통합 (아직 최초 적용 단계)
- V1 최초 적용 이후 스키마 변경은 V2, V3 순서로 새 파일 추가

### API

- REST — `GET` 조회 / `POST` 생성 / `PUT` 전체수정 / `DELETE` 삭제
- **에러 응답 분리** — API는 텍스트, 페이지는 HTML.
  `@RestControllerAdvice(annotations = RestController.class)`로 범위를 한정하고,
  `CustomErrorController`가 `/api`로 시작하면 `ResponseEntity`, 아니면 HTML forward
- 최종 `Exception` 핸들러는 `e.getMessage()`를 노출하지 않고 고정 문구 사용 (DB 스키마 노출 방지)

### 프론트

- 경로는 **절대경로** (`/views/...`, `/js/...`). 폴더 깊이가 달라지면 상대경로가 깨짐
- 에러 페이지는 forward라 URL이 원래 주소에 머무름 → CSS도 절대경로 필수
- `common.css` 통합 디자인 시스템. 색상은 CSS 변수 (`--bg`, `--text`, `--border`, `--surface`, `--accent`)
- 다크모드 — OS 설정(`prefers-color-scheme`) 기본값 + 토글 버튼, localStorage 저장
- UI/UX는 간결하게, 기능 우선

### 빌드

- **`-parameters` 컴파일 옵션 필수** — `build.gradle`과 IDE 양쪽 모두.
  Spring 7.0 / MyBatis 조합에서 이게 없으면 `@PathVariable`, `#{}` 바인딩이 실패함

---

## 협업 방식 (AI 활용)

- **직접 작성** — 판단이 들어가는 로직(검증, 설계, 알고리즘). 백엔드 코어 약 70%
- **위임** — 답이 하나인 기계적 변경(프론트 DOM·CSS, 보일러플레이트). 위임한 코드도 diff 검토
- **원칙** — 위임한 코드도 한 줄로 설명 못 하면 넘어가지 않는다
- 완성 코드를 통째로 받지 않고 **단계별 힌트를 받아 직접 작성한 뒤 검증**받는 방식
- 스프린트마다 "깊게 팔 영역"을 하나씩 지정
- 리뷰 — 기능 단위 QA + 스프린트 종료 시 전체 리뷰 1회. 발견 항목은 로드맵에 적고 즉시 고치지 않음
- **YAGNI 우선** — 지금 필요한 것만 고치고 나머지는 해당 기능 만들 때. 고칠 목록이 길면 로드맵으로 잘라서 진행
