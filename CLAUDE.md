# CLAUDE.md — 사이버 훈련 자산 구현 가이드

> 이 파일은 자산 구현 시 공통 유의사항을 정리한 것이다.
> 외부 포털 서버(01) 구현 과정에서 도출된 교훈을 기반으로 작성되었다.

---

## 프로젝트 구조

```
assets/<자산번호>_<자산명>/
├── setup.sh              # 원클릭 배포 스크립트
├── .env.example          # 환경변수 템플릿
├── Dockerfile            # Docker 테스트용
├── docker-compose.yml    # 풀스택 로컬 테스트용
├── src/
│   ├── backend/          # 백엔드 소스
│   ├── frontend/         # 프론트엔드 소스 (해당 시)
│   └── config/           # Nginx, systemd 등 설정 파일
├── sql/                  # DB 스키마 + 시드데이터
└── screenshots/          # Playwright 테스트 스크린샷
```

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

### Docker 테스트 시 HTTP 서버 블록
- Docker 로컬 테스트에서는 TLS 없이 HTTP(80)로 접근하므로, HTTP server 블록에도 프록시/정적파일 설정을 넣어야 한다
- 프로덕션(VM 배포)에서는 HTTP→HTTPS 리다이렉트만 유지

---

## Docker 테스트 환경

### docker-compose.yml 작성 규칙
- 한글 디렉토리명이 포함되면 이미지 이름이 깨진다 → `image:` 속성을 명시적으로 지정
```yaml
portal:
  image: mois-portal:latest   # 명시적 이미지 이름
  build: .
```

### DB healthcheck 필수
- FastAPI가 DB 연결을 시도하기 전에 PostgreSQL이 준비되어야 한다
```yaml
db:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U user -d dbname"]
    interval: 5s
    retries: 10
portal:
  depends_on:
    db:
      condition: service_healthy
```

### 환경변수로 DB_HOST 오버라이드
- docker-compose에서 `DB_HOST=db` (서비스명)로 오버라이드
- .env.example에는 실제 IP(`192.168.100.20`)를 기본값으로 유지

---

## 프론트엔드 (React) 유의사항

### API Base URL
- 프론트엔드의 API base URL은 `.env` 또는 `api.js`에 설정
- Docker 테스트 시에는 `localhost`로 접근하므로 환경변수 또는 Vite proxy 설정 활용
- **취약점은 자산별 설계 문서에 명시된 것만 구현한다** — 설계서에 없는 취약점을 임의로 추가하지 않는다

### Playwright 테스트
- SPA 라우팅 시 `waitUntil: 'networkidle'`이 타임아웃될 수 있다
- `waitUntil: 'load'`로 변경하고 타임아웃을 15~20초로 설정
- Docker 내에서 실행 시 `host.docker.internal`로 호스트 접근

---

## setup.sh 작성 규칙

1. `set -e`로 에러 시 즉시 중단
2. root 권한 확인 (`$EUID`)
3. 진행 상황 번호 출력 (`[1/9]`, `[2/9]`, ...)
4. 완료 후 접속 URL, 주의사항 출력
5. DB 서버 별도 안내 (원격 DB인 경우 init.sql 실행 방법)
6. UFW 방화벽 설정 포함 (취약 포트 개방 시 주석으로 표시)

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
