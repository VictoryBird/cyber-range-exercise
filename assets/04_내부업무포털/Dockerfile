FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /app

# 시스템 의존성 설치 (LDAP, PostgreSQL)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libldap2-dev \
    libsasl2-dev \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python 의존성 설치
COPY src/requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt

# 소스 코드 복사
COPY src/intranet_portal/ /app/

# 정적 파일 디렉토리 생성
RUN mkdir -p /var/www/intranet/static /var/log/intranet-portal

EXPOSE 8000

CMD ["gunicorn", "intranet_portal.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "120"]
