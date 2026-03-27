FROM node:20-slim AS frontend-build
WORKDIR /app/frontend
COPY src/frontend/package.json ./
RUN npm install --silent
COPY src/frontend/ ./
RUN npm run build

FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends nginx curl && rm -rf /var/lib/apt/lists/*

COPY src/backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/backend/ ./backend/
COPY .env.example ./backend/.env
COPY conf/nginx/minwon.conf /etc/nginx/sites-available/default

COPY --from=frontend-build /app/frontend/dist /var/www/minwon/

RUN mkdir -p /opt/minwon/data /var/log/minwon && \
    sed -i 's|/var/www/minwon|/var/www/minwon|g' /etc/nginx/sites-available/default

EXPOSE 80 8000 9000

CMD sh -c "cd /app/backend && uvicorn main:app --host 0.0.0.0 --port 8000 & nginx -g 'daemon off;'"
