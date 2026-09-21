# AWS 인프라 기록

AWS 콘솔에서 **무엇을 어떤 값으로 만들었고 왜 그랬는지**. 콘솔 클릭은 이력이 안 남아서 여기에 남긴다.
실무는 이런 자원을 코드(Terraform·CDK)로 만들어 PR 로 리뷰한다 — 한 대짜리 개인 프로젝트라 콘솔 + 이 문서로 대신한다.
"왜"의 정본은 ADR-002 보완 · ADR-042, 단계 진행은 진행상황.md "1차 배포". 이 문서는 **지금 AWS 에 무엇이 있는가 + 자주 하는 조작**.

> **값은 적지 않는다** (CLAUDE.md "비밀값 · 개인정보"). IP·pem 위치·DB 비밀번호 같은 값은 **저장소 밖 개인 보관처**에. 여기엔 `<EC2_HOST>` 처럼 이름만.

---

## 지금 있는 것 (2026-09-17 기준)

| 자원 | 이름 / 값 | 비고 |
|---|---|---|
| 리전 | 서울 `ap-northeast-2` | 콘솔 오른쪽 위가 서울인지 먼저 확인. 다른 리전이면 인스턴스가 안 보인다 |
| EC2 인스턴스 | `ledger-prod` | Ubuntu Server 26.04 LTS, **arm64**, 접속 계정 `ubuntu` |
| 인스턴스 유형 | **t4g.small** (2vCPU · 2GB) | $0.0208/시간. medium 으로 만들었다가 같은 날 내림. Ollama 설치 직전에 t4g.medium 으로 (로드맵) |
| 크레딧 사양 | **Standard** | 기본값 Unlimited 에서 변경. CPU 를 오래 써도 추가 요금 없음 (대신 크레딧이 떨어지면 느려짐) |
| 디스크 | 30GB gp3 | 기본 8GB 에서 변경. **늘릴 수는 있어도 줄일 수는 없다** |
| 키 페어 (내 접속용) | `ledger-admin` (ED25519, `.pem`) | AWS 가 생성. 다운로드는 생성 시 1회뿐 — 잃어버리면 재발급 불가 |
| 키 페어 (CD 배포용) | `ledger-deploy` (ED25519, 2026-09-18) | **AWS 키 페어가 아니라 맥에서 직접 생성**(`ssh-keygen`). 공개키는 `deploy` 계정 `authorized_keys`, 개인키는 GitHub Secrets. passphrase 없음. 유출되면 새로 만들어 갈아 끼우면 된다 |
| 보안 그룹 | `launch-wizard-1` | 인바운드 22 = **내 IP 만** / 80 · 443 = 전체. 8080 · 3306 은 열지 않음 |
| 탄력적 IP | 1개, `ledger-prod` 에 연결 | 재시작해도 IP 고정. **인스턴스 없이 혼자 남으면 그것대로 과금** — 인스턴스를 지울 땐 같이 릴리스 |
| MySQL | **8.4.11** (우분투 패키지, 2026-09-17 설치) | `ledger_db` + 앱 계정 `ledger_app`@`localhost`. root 는 `auth_socket`(비번 없음, 소켓 인증). 3306 은 `127.0.0.1` 바인딩 |
| Java | **17.0.20** (`openjdk-17-jre-headless`, arm64) | JRE 만 — 빌드는 맥·CI, 서버는 실행만 |
| 앱 실행 유저 | `ledger` (UID 999) | 시스템 계정 · 셸 `nologin` · 비번 없음(`!`) · 홈 없음. systemd `User=` 로 쓴다 (ADR-043 과 같은 판단) |
| 배포 계정 | `deploy` (2026-09-18) | CD 전용. 셸 `/bin/bash`(SSH 로 들어와 jar 를 놓아야 하므로) · 비번 잠김, 키만 · `/opt/ledger` 소유 · sudo 는 `systemctl restart ledger` **한 줄만**(`/etc/sudoers.d/ledger-deploy`). `ledger.env` 는 못 읽는다 |
| 앱 서비스 | `ledger.service` (systemd, 2026-09-18) | **`active (running)`** · `enable` 됨 · `Restart=always`. jar 는 `/opt/ledger/ledger.jar`(고정 이름), 비밀값은 `/etc/ledger/ledger.env`(root 600). 2-5 에서 첫 배포·재부팅 자동 기동 확인 |
| OS 타임존 | `Asia/Seoul` | MySQL 설치 **전에** 바꿨다. MySQL `time_zone=SYSTEM` 이 OS 를 따라가므로 순서가 중요 (ADR-026) |
| IAM ID 제공업체 | `token.actions.githubusercontent.com` (OIDC, 2026-09-19) | GitHub Actions 가 발급한 토큰을 AWS 가 검증하도록 등록. 대상(Audience) `sts.amazonaws.com`. **이것만으론 권한이 0** — 권한은 역할에 붙는다 |
| IAM 정책 | `ledger-deploy-sg-ssh` (2026-09-19) | `ec2:AuthorizeSecurityGroupIngress` · `ec2:RevokeSecurityGroupIngress` **두 개만**, 리소스는 `launch-wizard-1` 보안그룹 하나의 ARN. 포트까지는 못 좁힌다(IAM 조건 키에 포트가 없음) — 진행상황.md 3-4 의 감수 |
| IAM 역할 | `ledger-github-deploy` (2026-09-19, 신뢰 정책 2026-09-20 수정) | GitHub Actions 가 OIDC 로 맡는 역할. 신뢰 정책 `sub` 는 **main 브랜치 두 형태만**(`repo:<OWNER>/<REPO>:ref:refs/heads/main` + 숫자 ID 가 박힌 `repo:<OWNER>@<OWNER_ID>/<REPO>@<REPO_ID>:...`). **실제로 오는 건 ID 형태** — 콘솔이 자동으로 채워주는 이름 형태만 두면 `Not authorized` 로 거절된다(3-6 실측). 권한은 `ledger-deploy-sg-ssh` 하나 |
| 도메인 | **`dotoree.app`** (2026-09-21, Cloudflare Registrar) | 1년 · 자동 갱신 켬 · 연 $14.20(원가 판매라 갱신가 동일). 네임서버는 Cloudflare 고정(이 등록기관의 조건). **AWS 자원이 아니라 Cloudflare 계정**(2FA TOTP)에 있다. `.app` 은 HSTS preload — 인증서 없이는 브라우저로 안 열린다 |
| DNS 레코드 | `A @` → 탄력적 IP / `CNAME www` → `dotoree.app` | 둘 다 **DNS only(회색 구름)**. 프록시를 켜면 HTTPS 를 Cloudflare 가 대신 끝내서 Nginx·certbot 이 할 일이 사라지고 인증도 가로막힌다. `www` 를 CNAME 으로 둔 건 IP 가 바뀔 때 A 한 줄만 고치려고(ETC) |
| Nginx | **1.28.3** (apt, 2026-09-21) | `/etc/nginx/sites-available/ledger`(→ `sites-enabled` 링크). 블록 4개 — 80·443 문지기(모르는 이름은 444 / TLS 거부) · 80→443 · 443→`127.0.0.1:8080`. `/actuator` 는 health 만 통과, 나머지 404. 설치 직후 원본은 `ledger.bak-certbot` |
| TLS 인증서 | Let's Encrypt, `dotoree.app` + `www` (2026-09-21) | certbot **4.0.0**(apt). `/etc/letsencrypt/live/dotoree.app/`(개인키 root 전용). 90일 — `certbot.timer` 가 만료 30일 이내일 때 갱신. 첫 만료 2026-12-20 |
| 예산 알림 | `ledger-monthly` 월 $30 | 실제 85% · 100% 도달, 예상 100% 도달 시 메일. **알림만 — 과금을 멈추지는 않는다** |

아직 없는 것 — S3 버킷, EC2 인스턴스 역할(백업을 S3 로 올릴 권한), SES. 각각 진행상황.md 5단계 · Sprint 2 에서.

## 비용 (월 추정)

730시간 + 디스크 30GB + 공인 IPv4, VAT 10% 포함, 환율 1,400원 가정. 시간당 가격은 콘솔 표시가(서울).

| 유형 | 메모리 | 시간당 | 월 |
|---|---|---|---|
| t4g.micro | 1GB | $0.0104 | 약 2.2만원 — 앱 + MySQL 로 꽉 차서 탈락 |
| **t4g.small (지금)** | 2GB | $0.0208 | **약 3.3만원** |
| t4g.medium | 4GB | $0.0416 | 약 5.7만원 — Ollama 부터 |
| t3.medium (원래 계획, x86) | 4GB | $0.052 | 약 6.8만원 |

인스턴스 외 고정비 — 디스크 약 $2.7 + 공인 IPv4 약 $3.65. **인스턴스를 중지해도 이 둘은 계속 나간다.**

### 중지하면 과금이 멈추나

| 상태 | 인스턴스(시간당) | 디스크 30GB | 탄력적 IP | 월 |
|---|---|---|---|---|
| 실행 중 (t4g.small) | 과금 (초 단위, 쓴 만큼) | 과금 | 과금 | 약 3.3만원 |
| **중지** | **0원** | 과금 | 과금 | 약 1만원 |
| 종료(삭제) + IP 릴리스 | 0원 | 0원 | 0원 | 0원 — 서버가 사라진다 |

- 중지는 "전원 끄기" — 디스크 내용(설치한 MySQL·데이터)은 그대로, 다시 시작하면 이어진다. 탄력적 IP 라 주소도 같다
- 오래 자리를 비울 때(며칠 이상) 중지해 두면 하루 약 700원이 준다. 단 24시간 운영이 목표라 **배포 URL 을 공개한 뒤엔 끄지 않는다** (UptimeRobot 이 장애로 본다)

## 왜 이렇게 골랐나 (면접용 한 줄씩)

- **ARM(t4g)** — 같은 사양에 x86 보다 약 20% 싸다. jar 는 아키텍처 무관이고 MySQL · Nginx · Ollama 가 arm64 를 공식 지원해서 묶이는 게 없다. 단 **ARM ↔ x86 은 유형 변경이 안 되고 새로 만들어야 한다** — 처음에 정해야 하는 유일한 것
- **small 로 시작** — 지금 올라가는 건 Spring Boot + MySQL 뿐. 4GB 는 Ollama 부터 필요한데 그 시점을 모른다. 유형 변경이 5분(실측)이라 미리 낼 이유가 없다
- **22번은 내 IP 만** — 전체로 열면 SSH 무차별 대입 시도가 바로 들어온다. 키 인증이라 뚫리진 않아도 로그가 오염되고 공격면이 넓어진다
- **80 · 443 만 열고 8080 은 닫음** — 사용자는 포트 없이 접속한다(http=80, https=443). Nginx 가 받아 `localhost:8080` 으로 넘긴다. 앱이 인터넷에 직접 노출되지 않아 `/actuator` 같은 경로를 밖에서 직접 찌를 수 없다
- **3306 은 닫음** — DB 는 같은 인스턴스의 앱만 접속(`localhost`). 밖에서 DB 를 볼 일이 있으면 SSH 터널
- **Standard 크레딧** — 예산이 고정인 개인 프로젝트는 "느려지는 것"이 "요금이 튀는 것"보다 낫다
- **Ubuntu 26.04 LTS** — MySQL 8.0 이 2026-04 지원 종료. 새 운영 서버는 최신 LTS 패키지를 쓴다
- **탄력적 IP** — 도메인 · GitHub Secrets(`EC2_HOST`) · 카카오 콘솔이 가리킬 주소가 재시작마다 바뀌면 안 된다

## 자주 하는 조작

### 접속

```
ssh -i <PEM_PATH> ubuntu@<EC2_HOST>
```

`~/.ssh/config` 에 `Host ledger` 로 등록해 두면 `ssh ledger`. 이 파일은 저장소 밖이라 IP 를 적어도 된다.

| 증상 | 원인 | 해결 |
|---|---|---|
| 반응 없다가 `timed out` | 집 IP 가 바뀜 (공유기 재시작, 다른 장소) | EC2 → 보안 그룹 → 인바운드 규칙 편집 → 22번 소스를 "내 IP" 로 다시 |
| `UNPROTECTED PRIVATE KEY FILE` | pem 권한이 넓음 | `chmod 400 <PEM_PATH>` |
| `Permission denied (publickey)` | 계정 · 키 경로 오타 | 계정은 `ubuntu`, `-i` 경로 확인 |
| `REMOTE HOST IDENTIFICATION HAS CHANGED` | 인스턴스를 새로 만들어 같은 IP 에 다른 서버 | `ssh-keygen -R <EC2_HOST>` 후 재접속 |

### MySQL 접속 · 확인

```
sudo mysql                      # root, 비번 없이 (auth_socket — sudo 가 곧 인증)
mysql -u ledger_app -p ledger_db   # 앱 계정으로
```

| 확인할 것 | 명령 | 기대 |
|---|---|---|
| 타임존 | `SELECT @@global.time_zone, NOW();` | `SYSTEM` + 한국 시각 |
| 앱 계정 권한 | `SHOW GRANTS FOR 'ledger_app'@'localhost';` | `USAGE ON *.*` + `ALL PRIVILEGES ON ledger_db.*` 두 줄만 |
| collation | `SHOW CREATE DATABASE ledger_db;` | `utf8mb4_0900_ai_ci` (맥·CI 와 같은 값, ADR-044) |
| 테이블 | `USE ledger_db; SHOW TABLES;` | 19개 — V1 의 18개 + `flyway_schema_history`. **이름은 전부 소문자** (ADR-045) |
| 메모리 | `free -h` | available 300Mi 아래면 스왑 검토 |

### DBeaver 로 운영 DB 보기 (SSH 터널)

**3306 을 열지 않고도 본다.** 보안 그룹에 3306 이 없고 MySQL 도 `127.0.0.1` 바인딩이지만,
SSH 로 먼저 서버에 들어간 뒤 그 통로 안에서 `localhost:3306` 에 붙으면 된다.
결과적으로 DB 에 닿으려면 **pem 키(가진 것) + DB 비번(아는 것)** 둘 다 필요해진다.

MySQL 커넥션을 새로 만들고 **두 탭을 나눠** 채운다 — SSH 탭은 "서버까지 가는 길", Main 탭은 "도착해서 누구로 어디에 붙나".

| 탭 | 항목 | 값 |
|---|---|---|
| SSH (`+ SSH, SSL, ...` 로 추가) | Host / Port | `<EC2_HOST>` / `22` |
| | User Name | `ubuntu` |
| | Authentication Method | Public Key → Private Key 에 `<PEM_PATH>` |
| Main | Server Host / Port | **`127.0.0.1`** / `3306` (서버 안에서 본 주소) |
| | Database | `ledger_db` |
| | Username / Password | `ledger_app` / `DB_PASSWORD` 값 |

- **root 로는 못 붙는다** — `auth_socket` 이라 비번 자체를 받지 않는다 (ADR-043). 관리자 작업은 SSH 에서 `sudo mysql`
- 확인 순서 — SSH 탭의 `Test tunnel configuration`(Connected) → 왼쪽 아래 `Test Connection`(8.4.11 표시)
- **커넥션 이름은 `ledger_db(EC2)`, Connection type 은 Production** 으로. 탭이 빨개지고 DELETE·UPDATE 에 확인창이 뜬다.
  로컬 `ledger_db` 와 헷갈려 운영 데이터를 지우는 사고를 막는 가장 싼 장치다
- 집 IP 가 바뀌면 이 터널도 SSH 와 같이 타임아웃 난다 → 보안 그룹 22번 소스를 "내 IP" 로 다시
- 이 방식은 나중에 서버가 늘거나 DB 를 밖으로 빼도 유지된다 — 사람은 터널·배스천을 거치고, 3306 은 앱 서버에만 연다

- 앱 계정 비밀번호는 해시로만 저장돼 **다시 꺼내볼 수 없다.** 잃어버리면 `ALTER USER 'ledger_app'@'localhost' IDENTIFIED BY '새 값';` 로 재설정하고 systemd `EnvironmentFile` 도 같이 고친다
- root 비번을 만들지 않은 이유는 ADR-043

### 인스턴스 유형 변경 (small ↔ medium)

1. 인스턴스 선택 → 인스턴스 상태 → **인스턴스 중지** ("종료(삭제)" 가 아님 — 종료는 디스크까지 지운다)
2. `중지됨` 이 되면 작업 → 인스턴스 설정 → **인스턴스 유형 변경** → `t4g.medium` → 변경
3. 인스턴스 상태 → **인스턴스 시작**
4. 확인 — 유형이 바뀌었는가 / 퍼블릭 IP 가 그대로인가 / 작업 → 인스턴스 설정 → 크레딧 사양 변경 에서 "무제한 모드" 가 **체크 해제**인가

운영 중엔 1~3 사이 몇 분간 서비스가 내려간다. systemd 자동 기동(2단계)이 돼 있으면 시작 후 앱은 알아서 올라온다.

### 앱 서비스 조작 (`ledger.service`)

```
sudo systemctl start ledger      # 지금 띄우기
sudo systemctl stop ledger
sudo systemctl restart ledger    # 배포 후
systemctl status ledger          # 상태 한 눈에 (active / 마지막 로그 몇 줄)
journalctl -u ledger -f          # 로그 실시간 (Ctrl+C 로 빠져나옴)
journalctl -u ledger -n 100      # 최근 100줄
journalctl -u ledger --since "10 min ago"
```

- 유닛 파일이나 `ledger.env` 를 고쳤으면 **`daemon-reload` 먼저**, 그다음 `restart`
- `enable` 은 "부팅 때마다", `start` 는 "지금". 별개다
- 기동 실패는 `Restart=always` 때문에 5초마다 반복된다 — `status` 에 재시작 횟수가 쌓이면 로그부터 본다

### Nginx · 인증서

```
sudo nginx -t && sudo systemctl reload nginx   # 설정 고친 뒤 — 검사 통과해야만 reload
sudo cat /etc/nginx/sites-available/ledger      # 지금 설정
sudo certbot certificates                       # 인증서·만료일
sudo certbot renew --dry-run                    # 갱신 리허설 (설정을 손으로 고친 뒤 꼭)
systemctl list-timers | grep certbot            # 자동 갱신 타이머
```

- 설정 파일을 채팅·문서에서 복사해 붙였다면 `grep -c '](' /etc/nginx/sites-available/ledger` 가 0 인지 (링크 오염 검사, 트러블슈팅 16)
- `restart` 가 아니라 `reload` — 연결을 끊지 않는다
- 인증서가 만료되면 `.app` 은 HSTS preload 라 **브라우저로 아예 안 열린다**. 타이머가 실패했는지부터 `journalctl -u certbot`

### 요금 확인

과금 정보 및 비용 관리 → 청구서(이번 달 누적) / Cost Explorer(일별). 예산 알림 메일이 오면 먼저 **EC2 대시보드에서 모르는 인스턴스가 떠 있는지**, 리전을 바꿔가며 확인.

### 전부 지울 때 (프로젝트 종료)

인스턴스 종료 → **탄력적 IP 릴리스** → 보안 그룹 · 키 페어 삭제 → 예산 삭제. 탄력적 IP 를 빼먹으면 매달 과금이 남는다.

## 키 파일 보관

- `.pem` 은 **iCloud·드롭박스로 동기화되는 폴더를 피한다** (맥의 "데스크탑 및 문서 폴더" 동기화가 켜져 있으면 `~/Documents` 도 올라간다). 표준 위치는 `~/.ssh/`, 권한 `400`
- 저장소 폴더 안에 두지 않는다. 실제 위치는 저장소 밖 개인 보관처에만 적어 둔다
- 첫 접속 때 나오는 `ED25519 key fingerprint ... (yes/no)` 는 "이 서버를 처음 본다"는 확인. `yes` 하면 `~/.ssh/known_hosts` 에 기록되고 다음부터 안 묻는다

## 계정 보안

- 루트 계정 **MFA**(로그인 때 비밀번호 + 휴대폰 앱의 6자리 코드) — 루트는 결제 수단에 무제한 권한이라, 털리면 비싼 인스턴스 수십 대로 수백만원이 청구되는 사고가 흔하다
  1. 휴대폰에 Google Authenticator 설치 (설정에서 Google 계정 백업 켜기 — 폰 분실 대비)
  2. 콘솔 오른쪽 위 계정 이름 → **보안 자격 증명** → **MFA 디바이스 할당**
  3. 디바이스 이름(영문·숫자·`-`) → **인증 관리자 앱** → **QR 코드 표시** → 앱의 `+` 로 스캔
  4. **MFA 코드 1** 에 지금 6자리, 약 30초 뒤 숫자가 바뀌면 **MFA 코드 2** 에 새 6자리 (같은 숫자 두 번은 실패) → **MFA 추가**
  5. 확인 — 로그아웃 후 재로그인 때 코드를 묻는가
  - **패스키 대신 OTP 를 고른 이유** (2026-09-17 실측) — 패스키는 등록한 브라우저(Safari·Chrome)의 저장소에 묶인다. Claude 내장 브라우저에선 "저장된 패스키가 없습니다"만 나오고 Touch ID 가 안 뜬다. OTP 는 숫자 입력이라 어느 브라우저에서든 된다
  - MFA 를 지우거나 바꾸려면 **MFA 로 인증하고 들어온 세션**이어야 한다 — 등록 전에 로그인해 둔 세션에선 "please ensure that you are authenticated with an MFA device" 로 거부된다. 로그아웃 → 재로그인
  - `MFA device already exists` 인데 목록은 (0) — QR 을 띄우는 순간 그 이름으로 기기가 먼저 만들어지고, 코드 2개를 넣어야 할당된다. 중간에 멈추면 안 보이는 미할당 기기가 남아 같은 이름이 충돌한다. **이름을 바꿔 다시** + 폰 앱의 옛 항목은 지우고 새 QR 을 스캔. 남은 미할당 기기는 무해(과금 없음). 지우려면 CloudShell 에서 `aws iam list-virtual-mfa-devices --assignment-status Unassigned` → `aws iam delete-virtual-mfa-device --serial-number <값>`
  - "코드가 유효하지 않음" 이 반복되면 휴대폰 시계를 자동 설정으로. 휴대폰을 바꾸기 전에 새 기기로 먼저 옮길 것
- 루트 계정에 **액세스 키를 만들지 않는다**. CD 나 백업에 AWS 권한이 필요해지면 IAM 역할 · 최소 권한 사용자로 (5단계)

## 비밀 · 식별자 목록표 (2026-09-19)

**값은 없다 — 이름, 어디에 있는지, 무엇을 여는지, 유출되면 무엇을 갈아 끼우는지.** 분류 기준은 CLAUDE.md "값 3단 분류".
사고가 난 뒤엔 침착하게 찾아볼 여유가 없어서, 교체 절차를 미리 적어 둔다.

| 이름 | 분류 | 있는 곳 | 무엇을 여는가 | 유출·분실 시 |
|---|---|---|---|---|
| AWS 루트 비밀번호 + MFA | 비밀 | 암호 관리처 + 폰 OTP | 계정 전체(결제 포함) | 비번 변경 → MFA 재등록 → 모르는 인스턴스·IAM 주체 확인 |
| `ledger-admin` 개인키(pem) | 비밀 | 맥 `~/.ssh/` | `ubuntu` — sudo 전권 | **재발급 불가.** 새 키쌍 생성 → `ubuntu` 의 `authorized_keys` 교체 → AWS 키 페어 삭제 |
| `ledger-deploy` 개인키 | 비밀 | 맥 `~/.ssh/` + GitHub Secret `EC2_SSH_KEY` | `deploy` — jar 교체 + `restart` 만 | `ssh-keygen` 새로 → `deploy` 의 `authorized_keys` 교체 → Secret 갱신. 내 접속은 안 끊긴다 |
| `DB_PASSWORD` (운영) | 비밀 | EC2 `/etc/ledger/ledger.env` + 개인 보관처 | `ledger_db` 전체 | `ALTER USER 'ledger_app'@'localhost' IDENTIFIED BY ...` → `ledger.env` → `restart` |
| `JWT_SECRET` (운영) | 비밀 | EC2 `ledger.env` | 로그인 토큰 서명(위조 가능해짐) | `openssl rand -base64 48` 새로 → `ledger.env` → `restart`. **전원 재로그인** |
| `AWS_ROLE_ARN` · `AWS_SG_ID` · `EC2_HOST` | 식별자 | GitHub Secrets + 개인 보관처 | 단독으론 아무것도 못 연다 | 교체 불필요. 공개 로그에 안 찍히게 Secret 에 둔 것 |
| `EC2_HOST_KEY` (서버 호스트 공개키) | 식별자 | GitHub Secret. 원본은 서버 `/etc/ssh/ssh_host_ed25519_key.pub`, 사본은 맥 `~/.ssh/known_hosts` | 아무것도 못 연다 — CD 가 "진짜 그 서버인가"를 확인하는 지문 | 따로 보관할 필요 없음(언제든 다시 꺼낼 수 있다). **서버를 새로 만들면 값이 바뀌므로 Secret 갱신** |
| `AWS_REGION` · `EC2_USER` | 공개 설정 | `ci.yml` 에 그대로 | — | — |
| CI 일회용 값(`ci_test_password` 등) | 공개 | `ci.yml` | 러너 안 일회용 DB | 해당 없음. **운영 값은 반드시 다르게** |
| `QA_PASSWORD` | 테스트 | 맥 셸 환경변수 | 로컬 테스트 계정 | — (운영 `test@test.com` 은 공개 전 정리 — 로드맵) |

- 역할 `ledger-github-deploy` 에는 **보관할 비밀이 없다** — OIDC 라 실행마다 1시간짜리 임시 자격을 받는다
- IAM 사용자는 0명으로 유지한다. 사용자를 만들면 장기 액세스 키가 생길 자리가 생긴다 — AWS 권한이 필요하면 역할로

## 작업 이력

| 날짜 | 작업 | 누가 |
|---|---|---|
| 2026-09-17 | `ledger-prod` 생성(t4g.medium) · 키 페어 · 보안 그룹 · 탄력적 IP 연결 · 크레딧 Standard | AI 가 콘솔 조작, 과금 클릭 전 사용자 확인 |
| 2026-09-17 | t4g.medium → t4g.small (중지 → 변경 → 시작, 5분) | AI 가 콘솔 조작 |
| 2026-09-17 | 예산 알림 `ledger-monthly` $30 | AI 가 콘솔 조작 |
| 2026-09-17 | pem 권한 설정 · SSH 첫 접속 확인 | 직접 |
| 2026-09-17 | 루트 MFA — 폰 OTP(Google Authenticator). 패스키(Touch ID)로 등록했다가 제거 | 직접 |
| 2026-09-17 | OS 타임존 KST → `apt upgrade`(169개) → 커널 재부팅 → MySQL 8.4.11 설치 → `mysql_secure_installation` | 직접 |
| 2026-09-17 | `ledger_db` 생성 · 앱 계정 `ledger_app` 생성 · `ledger_db.*` 권한 부여 (ADR-043 · ADR-044) | 직접 |
| 2026-09-17 | Java 17 JRE(headless) 설치 · 앱 실행 유저 `ledger` 생성(시스템 계정 · `nologin` · 비번 없음) | 직접 |
| 2026-09-18 | `/opt/ledger`·`/etc/ledger` 생성 · `ledger.env`(root 600, 값 4개) · `ledger.service` 작성 · `daemon-reload`·`enable` | 직접 |
| 2026-09-18 | 2-5 수동 첫 배포 — jar `scp` → `systemctl start` → Flyway V1 적용(19테이블). 테이블명 대소문자로 1회 실패 후 DB 재생성(ADR-045) · 가입·로그인·거래 확인 · 타임존 3계층 확인 · 재부팅 자동 기동 확인 | 직접 |
| 2026-09-18 | DBeaver 운영 DB 커넥션 — SSH 터널(pem) + `ledger_app`. 3306 은 열지 않음 | 직접 |
| 2026-09-18 | 3단계 CD 준비 — 배포 키쌍 `ledger-deploy` 생성 · `deploy` 계정 + `authorized_keys` · `/opt/ledger` 소유권 이전 · sudoers 한 줄(`restart` 만) · 권한 경계 실측(stop·`ledger.env` 거부) | 직접 |
| 2026-09-19 | 3-4 CD 권한(B안) — IAM **OIDC 공급자** 등록. 배포할 때만 보안 그룹 22번에 러너 IP 를 열고 닫기 위한 권한 준비 | AI 가 콘솔 조작(내장 브라우저) |
| 2026-09-19 | IAM 정책 `ledger-deploy-sg-ssh` 생성(시각적 편집기, EC2 2작업 + SG ARN 1개) | AI 가 콘솔 조작(내장 브라우저) |
| 2026-09-19 | IAM 역할 `ledger-github-deploy` 생성 — 웹 자격 증명(OIDC) · main 브랜치 한정 · 정책 1개 연결 | AI 가 콘솔 조작(내장 브라우저) |
| 2026-09-20 | `ledger-github-deploy` 신뢰 정책 수정 — `sub` 에 숫자 ID 형태 추가(3-6 실패 원인) | AI 가 콘솔 조작(내장 브라우저) |
| 2026-09-21 | Cloudflare 가입 · 2FA(TOTP) → `dotoree.app` 구매(1년, 자동 갱신) → DNS `A @` · `CNAME www`(DNS only). `dig +short` 로 두 이름 모두 탄력적 IP 확인 | 직접 (이름 후보 가용성·겹침 검색은 AI) |
| 2026-09-21 | Nginx 설치 · 설정(80 문지기 · 앱 프록시) → certbot 인증서 발급(`--dry-run` 먼저) · 80→443 → 설정 재작성(443 문지기 · `/actuator` 404) · `renew --dry-run` 재확인 | 직접 (AI 안내) |
