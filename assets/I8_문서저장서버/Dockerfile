FROM python:3.11-slim

WORKDIR /opt/docstorage

# 시스템 의존성
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

# Python 패키지
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스코드 복사
COPY src/backend/ .

# 파일 저장 디렉토리
RUN mkdir -p /opt/docstorage/files/{작전계획,군수보급,인사명령,통신보안,일반행정}

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
