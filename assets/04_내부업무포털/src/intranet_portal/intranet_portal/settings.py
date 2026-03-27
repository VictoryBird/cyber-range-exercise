"""
Django settings for MOIS 내부 업무 포털 (Internal Business Portal).
"""

import os
from pathlib import Path
from urllib.parse import quote_plus
from dotenv import load_dotenv

# .env 파일 로드
load_dotenv(os.path.join(Path(__file__).resolve().parent.parent.parent.parent, '.env'))

BASE_DIR = Path(__file__).resolve().parent.parent

SECRET_KEY = os.getenv('DJANGO_SECRET_KEY', 'django-insecure-mois-intranet-key-2026-do-not-use-in-prod')

DEBUG = os.getenv('DJANGO_DEBUG', 'False').lower() in ('true', '1', 'yes')

ALLOWED_HOSTS = os.getenv('DJANGO_ALLOWED_HOSTS', 'intranet.mois.local,192.168.100.10,localhost').split(',')

ENVIRONMENT = os.getenv('ENVIRONMENT', 'production')

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    # Third-party
    'rest_framework',
    'corsheaders',
    'django_filters',
    # Local apps
    'accounts',
    'notices',
    'approvals',
    'work_requests',
    'search',
    'admin_api',
    'core',
]

MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    'core.middleware.AuditLogMiddleware',
]

ROOT_URLCONF = 'intranet_portal.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [BASE_DIR / 'templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'intranet_portal.wsgi.application'

# Database — PostgreSQL (원격: 192.168.100.20)
# DB 비밀번호에 특수문자가 포함되므로 URL 인코딩 필요 (CLAUDE.md 참고)
DB_PASSWORD_RAW = os.getenv('DB_PASSWORD', 'Intr@n3t#DB2026!')

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': os.getenv('DB_NAME', 'mois_intranet'),
        'USER': os.getenv('DB_USER', 'intranet_app'),
        'PASSWORD': DB_PASSWORD_RAW,
        'HOST': os.getenv('DB_HOST', '192.168.100.20'),
        'PORT': os.getenv('DB_PORT', '5432'),
        'OPTIONS': {
            'connect_timeout': 10,
        },
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
     'OPTIONS': {'min_length': 8}},
]

# Authentication backends
# LDAP 인증을 우선 시도하고, 실패 시 Django 기본 인증으로 폴백
AUTHENTICATION_BACKENDS = [
    'accounts.ldap_backend.MockLDAPBackend',
    'django.contrib.auth.backends.ModelBackend',
]

# LDAP/AD 설정 (django-auth-ldap 용, 실제 AD 연결 시 활성화)
AUTH_LDAP_SERVER_URI = os.getenv('AD_LDAP_URI', 'ldap://192.168.100.50:389')
AUTH_LDAP_BIND_DN = os.getenv('AD_BIND_DN', 'cn=svc_intranet,ou=ServiceAccounts,dc=corp,dc=mois,dc=local')
AUTH_LDAP_BIND_PASSWORD = os.getenv('AD_BIND_PASSWORD', 'Sv(Ldap#2026')
AUTH_LDAP_USER_SEARCH_BASE = os.getenv('AD_USER_SEARCH_BASE', 'ou=People,dc=corp,dc=mois,dc=local')

# ============================================
# [취약점] VULN-SessionWeakness: 세션 쿠키 보안 설정 미흡
# 안전한 설정:
#   SESSION_COOKIE_HTTPONLY = True   (JS에서 쿠키 접근 차단)
#   SESSION_COOKIE_SECURE = True    (HTTPS에서만 쿠키 전송)
#   SESSION_COOKIE_AGE = 3600       (1시간)
#   SESSION_EXPIRE_AT_BROWSER_CLOSE = True
# ============================================
SESSION_COOKIE_AGE = 86400 * 7              # [취약 설정] 7일 (과도하게 긴 세션)
SESSION_COOKIE_HTTPONLY = False              # [취약 설정] JavaScript에서 쿠키 접근 가능
SESSION_COOKIE_SECURE = False               # [취약 설정] HTTP에서도 쿠키 전송
SESSION_EXPIRE_AT_BROWSER_CLOSE = False     # [취약 설정] 브라우저 종료 후에도 세션 유지
CSRF_COOKIE_HTTPONLY = False                # [취약 설정] CSRF 토큰도 JS 접근 가능

SESSION_ENGINE = 'django.contrib.sessions.backends.db'

# Internationalization
LANGUAGE_CODE = 'ko-kr'
TIME_ZONE = 'Asia/Seoul'
USE_I18N = True
USE_TZ = True

# Static files
STATIC_URL = '/static/'
STATIC_ROOT = '/var/www/intranet/static/'
STATICFILES_DIRS = [BASE_DIR / 'static']

# Media files
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# DRF settings
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework.authentication.SessionAuthentication',
        'rest_framework.authentication.BasicAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
    'PAGE_SIZE': 20,
    'DEFAULT_FILTER_BACKENDS': [
        'django_filters.rest_framework.DjangoFilterBackend',
        'rest_framework.filters.SearchFilter',
        'rest_framework.filters.OrderingFilter',
    ],
}

# CORS (내부망 전용)
CORS_ALLOWED_ORIGINS = [
    'http://intranet.mois.local',
    'http://intranet.mois.local:8080',
    'http://192.168.100.10',
    'http://192.168.100.10:8080',
]

# Login redirect
LOGIN_URL = '/accounts/login/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/accounts/login/'

# Logging
LOG_DIR = os.getenv('LOG_DIR', '/var/log/intranet-portal')

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'formatters': {
        'verbose': {
            'format': '{asctime} [{levelname}] {name}: {message}',
            'style': '{',
        },
        'json': {
            'format': '{message}',
            'style': '{',
        },
    },
    'handlers': {
        'console': {
            'class': 'logging.StreamHandler',
            'formatter': 'verbose',
        },
        'app_file': {
            'class': 'logging.FileHandler',
            'filename': os.path.join(LOG_DIR, 'app.log') if os.path.isdir(LOG_DIR) else '/tmp/intranet-app.log',
            'formatter': 'verbose',
        },
        'audit_file': {
            'class': 'logging.FileHandler',
            'filename': os.path.join(LOG_DIR, 'audit.log') if os.path.isdir(LOG_DIR) else '/tmp/intranet-audit.log',
            'formatter': 'json',
        },
    },
    'loggers': {
        'django': {
            'handlers': ['console', 'app_file'],
            'level': os.getenv('LOG_LEVEL', 'INFO'),
            'propagate': True,
        },
        'audit': {
            'handlers': ['audit_file', 'console'],
            'level': 'INFO',
            'propagate': False,
        },
        'accounts': {
            'handlers': ['console', 'app_file'],
            'level': 'DEBUG',
            'propagate': False,
        },
    },
}
