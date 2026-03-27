FROM debian:12-slim

# 시스템 패키지
RUN apt-get update && apt-get install -y --no-install-recommends \
    nginx \
    php8.2-fpm \
    php8.2-json \
    php8.2-mbstring \
    && rm -rf /var/lib/apt/lists/*

# 디렉토리 구조
RUN mkdir -p /var/www/update-server/{updates,admin/assets,logs}

# 소스 파일 복사
COPY src/admin/ /var/www/update-server/admin/
COPY src/updates/ /var/www/update-server/updates/
COPY conf/nginx/update-server.conf /etc/nginx/sites-available/update-server

# Nginx 설정
RUN ln -sf /etc/nginx/sites-available/update-server /etc/nginx/sites-enabled/ && \
    rm -f /etc/nginx/sites-enabled/default

# 시드 패치 파일 (플레이스홀더)
RUN dd if=/dev/urandom of=/var/www/update-server/updates/SecurityPatch_KB2024001.exe bs=1024 count=2400 2>/dev/null && \
    dd if=/dev/urandom of=/var/www/update-server/updates/OfficeUpdate_KB2024002.msi bs=1024 count=15360 2>/dev/null && \
    dd if=/dev/urandom of=/var/www/update-server/updates/NetworkDriver_KB2024003.exe bs=1024 count=5120 2>/dev/null

# 로그 디렉토리 및 권한
RUN touch /var/www/update-server/logs/download.log && \
    chown -R www-data:www-data /var/www/update-server

EXPOSE 80

# PHP-FPM + Nginx 시작
CMD service php8.2-fpm start && nginx -g "daemon off;"
