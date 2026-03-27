FROM python:3.11-slim AS historian-api

WORKDIR /opt/historian/app

# 패키지 설치
COPY src/backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 소스 복사
COPY src/backend/ .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
