# ============================================================
# D1 외부 포털 서버 — Docker 테스트용 (Nginx + 정적 파일)
# ============================================================
FROM nginx:1.24-alpine

# 정적 파일 복사
COPY src/webapp/index.html /var/www/mnd-portal/
COPY src/webapp/notice.html /var/www/mnd-portal/
COPY src/webapp/notice_view.html /var/www/mnd-portal/
COPY src/webapp/search.html /var/www/mnd-portal/
COPY src/webapp/contact.html /var/www/mnd-portal/
COPY src/webapp/css/ /var/www/mnd-portal/css/
COPY src/webapp/js/ /var/www/mnd-portal/js/

# Nginx 설정 (Docker용 — HTTP only)
RUN rm /etc/nginx/conf.d/default.conf
COPY conf/nginx/docker-mnd-portal.conf /etc/nginx/conf.d/mnd-portal.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
