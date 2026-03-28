# CLAUDE.md — 사이버 훈련 자산 구현 가이드

> 이 파일은 자산 구현 시 공통 유의사항을 정리한 것이다.
> 1차 구현 및 테스트 과정에서 도출된 교훈을 기반으로 작성되었다.

---

## 프로젝트 구조

```
assets/<자산번호>_<자산명>/
├── setup.sh              # 원클릭 배포 스크립트 (VM 네이티브 설치)
├── .env.example          # 환경변수 템플릿
├── src/
│   ├── backend/          # 백엔드 소스
│   ├── frontend/         # 프론트엔드 소스 (해당 시)
│   └── config/           # Nginx, systemd 등 설정 파일
├── sql/                  # DB 스키마 + 시드데이터
└── conf/                 # 서비스 설정 파일 (nginx, systemd 등)
```

---

## 배포 원칙

### VM 네이티브 설치 원칙
- **모든 자산은 VMware VM에 직접 설치한다** — Docker를 사용하지 않는다
- 예외: 07 AI어시스턴트(Ollama+OpenWebUI), D4-D5 허니팟(Cowrie+SNARE)은 Docker 허용
- Dockerfile, docker-compose.yml은 생성하지 않는다 (예외 자산 제외)

### 배포 브랜치 구조
- **main 브랜치**: 취약점 주석 포함 원본 소스 + 설계 문서 (개발/레드팀용)
- **deploy 브랜치**: 취약점 주석 제거 버전 (VM 배포/블루팀용)
- `scripts/build_deploy.py`로 주석 제거 빌드, `scripts/push_deploy.sh`로 deploy 브랜치 갱신

---

## setup.sh 작성 규칙

1. `set -e`로 에러 시 즉시 중단
2. `SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"` 반드시 정의
3. root 권한 확인 (`$EUID`)
4. 진행 상황 번호 출력 (`[1/9]`, `[2/9]`, ...)
5. **파일 존재 확인 후 복사**: `[ -f "${SCRIPT_DIR}/conf/file" ] || { echo "[ERROR]..."; exit 1; }`
6. **모든 파일 경로는 `${SCRIPT_DIR}` 기반** — 절대 경로 하드코딩 금지
7. 완료 후 접속 URL, 주의사항 출력
8. UFW 방화벽 설정 포함 (취약 포트 개방 시 주석으로 표시)
9. **소프트웨어 버전 하드코딩 금지** — `apt-get install postgresql`로 최신 버전 설치, 설치 후 `pg_config --version` 등으로 버전 감지

---

## PostgreSQL 유의사항

### postgresql.conf 덮어쓰기 금지
- Ubuntu/Debian PostgreSQL 패키지의 기본 `postgresql.conf`에는 `data_directory` 등 시스템 필수 설정이 포함됨
- **통째로 덮어쓰면 클러스터 시작 실패** (`Error: Invalid data directory for cluster`)
- **올바른 방법**: `conf.d/` 디렉토리에 오버라이드 파일을 넣는다
```bash
# 원본 postgresql.conf에 include_dir 추가
grep -q "include_dir = 'conf.d'" ${PG_CONF_DIR}/postgresql.conf || \
    echo "include_dir = 'conf.d'" >> ${PG_CONF_DIR}/postgresql.conf

# 커스텀 설정은 conf.d/에 배포
cat > ${PG_CONF_DIR}/conf.d/00_custom.conf << 'PGCONF'
listen_addresses = '*'
log_statement = 'none'
...
PGCONF
```

### SQL 파일 실행 시 권한 문제
- `sudo -u postgres psql -f /home/user/sql/init.sql`은 **Permission denied** 발생
- postgres 유저는 다른 사용자의 홈 디렉토리를 읽을 수 없다
- **해결**: 임시 디렉토리로 복사 후 실행
```bash
SQL_TMP=$(mktemp -d)
cp ${SCRIPT_DIR}/sql/*.sql ${SQL_TMP}/
chown -R postgres:postgres ${SQL_TMP}
sudo -u postgres psql -f ${SQL_TMP}/init.sql
rm -rf ${SQL_TMP}
```

### 버전 하드코딩 금지
- `postgresql-15`, `/etc/postgresql/15/main` 등 버전 번호를 하드코딩하지 않는다
- 설치 후 버전 자동 감지:
```bash
apt-get install -y postgresql postgresql-contrib
PG_VER=$(pg_config --version | grep -oP '\d+' | head -1)
PG_CONF_DIR="/etc/postgresql/${PG_VER}/main"
```

---

## DB 스키마 — 백엔드 코드와 일치 필수

### 컬럼명 불일치 방지
- **DB DDL의 컬럼명은 반드시 백엔드 코드의 SQL 쿼리와 일치해야 한다**
- 설계 문서에서 `notice_id`로 정의했어도 백엔드가 `id`로 쿼리하면 DB도 `id`를 사용해야 한다
- 1차 구현에서 발생한 불일치 예시:

| 설계/DDL | 백엔드 SQL | 문제 |
|---|---|---|
| `notice_id` | `id` | 컬럼명 불일치 → 조회 실패 |
| `author_name` | `author` | 컬럼명 불일치 |
| `is_pinned` | `is_public` | 컬럼명 + 의미 불일치 |
| `password_hash` | `password` | 컬럼명 불일치 |

### DB 계정 일치
- 백엔드 `.env`에 설정된 DB 계정(`portal_app`)은 반드시 DB의 `00_roles.sql`에 생성되어야 한다
- 1차 구현에서 01번 서버가 `portal_app` 계정을 사용하는데 DB에 해당 계정이 없어서 연결 실패

### 원칙
1. **백엔드 코드를 먼저 작성**하고
2. **코드의 SQL 쿼리에서 사용하는 컬럼명으로 DDL을 작성**한다
3. `.env`의 DB 계정은 `00_roles.sql`에 반드시 포함

---

## Python (FastAPI) 백엔드 유의사항

### databases 라이브러리 버전 호환
- `databases` 패키지는 `sqlalchemy<1.5`를 요구한다
- `sqlalchemy==2.x`와 호환되지 않음
- **사용할 버전**: `sqlalchemy==1.4.50`, `databases[asyncpg]==0.7.0`

### databases 쿼리 파라미터 형식
- `$1, $2` 형식이 아니라 `:param` 형식(named parameter)을 사용해야 한다
- 값은 dict로 전달: `await db.fetch_all(query, {"id": 1, "limit": 20})`
- **잘못된 예**: `await db.fetch_all("SELECT * FROM t WHERE id = $1", [1])`
- **올바른 예**: `await db.fetch_all("SELECT * FROM t WHERE id = :id", {"id": 1})`

### COUNT 쿼리와 LIMIT/OFFSET 분리
- COUNT 쿼리에는 `limit`, `offset` 파라미터를 포함하지 않는다
- 데이터 쿼리에만 `limit`, `offset`을 포함한다
```python
count_values = {k: v for k, v in values.items() if k not in ("limit", "offset")}
total = await db.fetch_val(count_query, count_values)
items = await db.fetch_all(data_query, values)
```

### DB 비밀번호 URL 인코딩
- 비밀번호에 `#`, `@`, `!` 등 특수문자가 포함되면 DB URL 파싱이 깨진다
- 특히 `#`은 URL fragment로 해석되어 뒷부분이 잘림 — **DB 연결 실패**
- `urllib.parse.quote_plus()`로 인코딩 필수
```python
from urllib.parse import quote_plus
password = quote_plus(self.DB_PASSWORD)
url = f"postgresql+asyncpg://{user}:{password}@{host}:{port}/{db}"
```

### pydantic-settings 환경변수 리스트 파싱
- `.env` 파일에서 리스트 타입은 JSON 배열 형식으로 작성해야 한다
- **잘못된 예**: `ALLOWED_ORIGINS=http://a.com,http://b.com`
- **올바른 예**: `ALLOWED_ORIGINS=["http://a.com","http://b.com"]`

---

## Nginx 설정 유의사항

### log_format 위치
- `log_format` 디렉티브는 `http` 블록 레벨에 위치해야 한다
- `server` 블록 안에 넣으면 Nginx가 시작 실패한다
- sites-available 파일은 `http` 블록 안에 include되므로 파일 최상단에 작성하면 된다

---

## 취약점 구현 원칙

- **설계 문서에 명시된 취약점만 구현한다** — 임의로 추가하지 않는다
- **자산 간 취약점 중복을 피한다** — 같은 유형의 취약점이 여러 자산에 반복되면 훈련 가치가 떨어진다. 각 자산은 고유한 공격 벡터를 가져야 한다
- 모든 의도적 취약점에는 코드 주석으로 `[취약점]` 또는 `[취약 설정]` 태그를 붙인다
- 주석에 올바른 구현 방법도 함께 명시한다 (블루팀 교육용)
- 취약점은 설계 문서의 VULN 번호와 매칭시킨다
- 취약점이 아닌 부분은 정상적이고 안전하게 구현한다

---

## 참고 문서 우선순위

자산 구현 시 아래 순서로 참고한다:

1. `자산설계_XX_자산명.md` — 해당 자산의 상세 설계 (메인)
2. `IP_대역_설계.md` — IP, 포트, 도메인, 환경변수
3. `레드팀_공격_플레이북.md` — 공격 절차, 페이로드
4. `블루팀_탐지_시나리오.md` — 로그 형식, 탐지 시그니처
5. `시나리오_및_자산_구성.md` — 자산 역할, 공격 벡터 개요
6. `CLAUDE.md` (이 파일) — 구현 공통 유의사항
