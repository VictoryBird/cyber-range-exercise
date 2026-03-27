# ============================================================
# Dockerfile — 웹메일 서버 로컬 테스트용
# Base: Debian 12 (Bookworm)
# ============================================================

FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV MAIL_DOMAIN=mois.local
ENV MAIL_HOST=192.168.100.11

# 기본 패키지
RUN apt-get update && apt-get install -y \
    curl wget gnupg2 ca-certificates openssl \
    procps supervisor rsyslog \
    && rm -rf /var/lib/apt/lists/*

# Postfix 설치 (preseed)
RUN echo "postfix postfix/mailname string ${MAIL_DOMAIN}" | debconf-set-selections && \
    echo "postfix postfix/main_mailer_type string 'Internet Site'" | debconf-set-selections && \
    apt-get update && apt-get install -y postfix && \
    rm -rf /var/lib/apt/lists/*

# Dovecot 설치
RUN apt-get update && apt-get install -y \
    dovecot-core dovecot-imapd dovecot-lmtpd dovecot-ldap \
    && rm -rf /var/lib/apt/lists/*

# Apache + PHP + Roundcube 설치
RUN apt-get update && apt-get install -y \
    apache2 libapache2-mod-php8.2 \
    php8.2 php8.2-fpm php8.2-xml php8.2-mbstring php8.2-intl \
    php8.2-ldap php8.2-sqlite3 php8.2-curl php8.2-zip php8.2-gd \
    roundcube roundcube-core roundcube-plugins roundcube-plugins-extra \
    && rm -rf /var/lib/apt/lists/*

# Apache 모듈 활성화
RUN a2enmod proxy_fcgi setenvif rewrite remoteip && \
    a2enconf php8.2-fpm 2>/dev/null || true

# vmail 사용자 생성
RUN groupadd -g 5000 vmail && \
    useradd -g vmail -u 5000 -d /var/mail/vhosts -s /usr/sbin/nologin vmail

# 디렉토리 생성
RUN mkdir -p /var/mail/vhosts/mois.local && \
    chown -R vmail:vmail /var/mail/vhosts && \
    mkdir -p /var/log/roundcube && \
    chown www-data:www-data /var/log/roundcube && \
    mkdir -p /var/lib/roundcube/db && \
    chown www-data:www-data /var/lib/roundcube/db

# 자체 서명 인증서 생성
RUN openssl req -x509 -nodes -days 3650 \
    -newkey rsa:2048 \
    -keyout /etc/ssl/private/mail.key \
    -out /etc/ssl/certs/mail.crt \
    -subj "/C=VL/ST=Valdoria/L=Capital/O=MOIS/OU=IT/CN=mail.mois.local" && \
    chmod 600 /etc/ssl/private/mail.key

# 설정 파일 복사
COPY conf/postfix/main.cf /etc/postfix/main.cf
COPY conf/postfix/master.cf /etc/postfix/master.cf
COPY conf/postfix/virtual_mailbox_maps /etc/postfix/virtual_mailbox_maps
COPY conf/postfix/virtual_mailbox_domains /etc/postfix/virtual_mailbox_domains
RUN postmap /etc/postfix/virtual_mailbox_maps

COPY conf/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
COPY conf/dovecot/conf.d/ /etc/dovecot/conf.d/
COPY conf/dovecot/dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext
COPY conf/dovecot/users /etc/dovecot/users
RUN chmod 600 /etc/dovecot/dovecot-ldap.conf.ext /etc/dovecot/users

# Docker 테스트용: LDAP 대신 passwd-file 인증 사용
RUN sed -i 's|^!include auth-ldap.conf.ext|#!include auth-ldap.conf.ext|' /etc/dovecot/conf.d/10-auth.conf && \
    sed -i 's|^#!include auth-passwdfile.conf.ext|!include auth-passwdfile.conf.ext|' /etc/dovecot/conf.d/10-auth.conf

COPY conf/roundcube/config.inc.php /etc/roundcube/config.inc.php
RUN chmod 640 /etc/roundcube/config.inc.php && \
    chown root:www-data /etc/roundcube/config.inc.php

COPY conf/apache/roundcube.conf /etc/apache2/sites-available/roundcube.conf
COPY conf/apache/roundcube-proxy.conf /etc/apache2/sites-available/roundcube-proxy.conf
RUN a2dissite 000-default.conf 2>/dev/null || true && \
    a2ensite roundcube.conf roundcube-proxy.conf && \
    echo 'Listen 8080' >> /etc/apache2/ports.conf

# 메일박스 생성
COPY seed/ /opt/seed/
RUN bash /opt/seed/seed_mailboxes.sh

# Supervisor 설정 (다중 프로세스 관리)
RUN cat > /etc/supervisor/conf.d/mail.conf <<'SEOF'
[supervisord]
nodaemon=true

[program:rsyslog]
command=/usr/sbin/rsyslogd -n
autorestart=true

[program:postfix]
command=/usr/sbin/postfix start-fg
autorestart=true

[program:dovecot]
command=/usr/sbin/dovecot -F
autorestart=true

[program:php-fpm]
command=/usr/sbin/php-fpm8.2 -F
autorestart=true

[program:apache2]
command=/usr/sbin/apache2ctl -D FOREGROUND
autorestart=true
SEOF

# 시드 메일 삽입 (서비스 시작 후 실행 필요 → entrypoint에서 처리)
RUN cat > /entrypoint.sh <<'EEOF'
#!/bin/bash
# 서비스 시작 후 시드 메일 삽입
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
sleep 5
bash /opt/seed/seed_emails.sh 2>/dev/null || true
wait
EEOF
RUN chmod +x /entrypoint.sh

EXPOSE 25 80 143 993 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
