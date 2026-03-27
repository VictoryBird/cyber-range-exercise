FROM node:20-slim AS frontend-build
WORKDIR /app/frontend
COPY src/frontend/package.json src/frontend/package-lock.json* ./
RUN npm install --silent
COPY src/frontend/ ./
RUN npm run build

FROM python:3.11-slim
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends nginx openssl && rm -rf /var/lib/apt/lists/*

COPY src/backend/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/backend/ ./backend/
COPY src/config/nginx/mois-portal.conf /etc/nginx/sites-available/default
COPY .env.example ./backend/.env

COPY --from=frontend-build /app/frontend/dist ./frontend/dist/

RUN mkdir -p /etc/nginx/ssl /var/log/mois-portal && \
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/nginx/ssl/mois-portal.key \
    -out /etc/nginx/ssl/mois-portal.crt \
    -subj "/C=VD/ST=Valdoria/L=Capital/O=MOIS/CN=www.mois.valdoria.gov" 2>/dev/null

RUN sed -i 's|/opt/mois-portal/frontend/dist|/app/frontend/dist|g' /etc/nginx/sites-available/default && \
    sed -i 's|/opt/mois-portal/venv/bin/uvicorn|uvicorn|g' /etc/nginx/sites-available/default

EXPOSE 80 443 8000

CMD sh -c "cd /app/backend && uvicorn main:app --host 0.0.0.0 --port 8000 &  nginx -g 'daemon off;'"
