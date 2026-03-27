# =============================================================================
# Dockerfile — 민원 처리 서버 워커 (자산 06)
# 테스트용 컨테이너: Python 3.11 + LibreOffice + Celery
# =============================================================================
# [취약점] VULN-06-01: LibreOffice 6.4.7 구버전 설치 + 매크로 보안 비활성화
# [취약점] VULN-06-02: Pillow 8.4.0 구버전 설치

FROM python:3.11-slim-bookworm

LABEL maintainer="exercise-admin"
LABEL description="Complaint Processing Worker (Asset 06)"

# 시스템 패키지 설치
# [취약점] VULN-06-01: LibreOffice를 시스템 패키지로 설치 (Docker에서는 최신 버전)
# 실제 VM 배포 시 setup.sh에서 6.4.7 아카이브 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    libreoffice-writer \
    libreoffice-calc \
    libreoffice-impress \
    poppler-utils \
    libmagic1 \
    && rm -rf /var/lib/apt/lists/*

# 작업 디렉토리
WORKDIR /opt/complaint-worker

# Python 패키지 설치
COPY src/worker/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드 복사
COPY src/worker/ .

# LibreOffice 매크로 보안 비활성화 설정 배포
# [취약 설정] VULN-06-01: 매크로 보안 레벨 0, /tmp를 신뢰 경로에 추가
RUN mkdir -p /root/.config/libreoffice/4/user/
COPY conf/libreoffice/disable_macro_security.xcu \
     /root/.config/libreoffice/4/user/registrymodifications.xcu

# 임시 처리 디렉토리 생성
RUN mkdir -p /tmp/processing /opt/complaint-worker/logs

# 환경변수
ENV PYTHONUNBUFFERED=1
ENV PROCESSING_TEMP_DIR=/tmp/processing

# Celery 워커 실행
CMD ["celery", "-A", "celery_app", "worker", \
     "--loglevel=info", "--concurrency=3", "-Q", "file_convert"]
