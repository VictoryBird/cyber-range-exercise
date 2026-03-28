import os
from urllib.parse import quote_plus

# FastAPI
API_HOST = os.getenv("API_HOST", "0.0.0.0")
API_PORT = int(os.getenv("API_PORT", "8000"))
ADMIN_TOKEN = os.getenv("ADMIN_TOKEN", "admin-token-mois-2026")

# DB
DB_HOST = os.getenv("DB_HOST", "192.168.92.208")
DB_PORT = int(os.getenv("DB_PORT", "5432"))
DB_NAME = os.getenv("DB_NAME", "complaint_db")
DB_USER = os.getenv("DB_USER", "complaint_rw")
DB_PASSWORD = os.getenv("DB_PASSWORD", "Compl@int_RW_2026!")

# MinIO
MINIO_ENDPOINT = os.getenv("MINIO_ENDPOINT", "192.168.92.203:9000")
MINIO_ACCESS_KEY = os.getenv("MINIO_ACCESS_KEY", "minio_access")
MINIO_SECRET_KEY = os.getenv("MINIO_SECRET_KEY", "minio_secret123")
MINIO_BUCKET = os.getenv("MINIO_BUCKET", "complaints")
MINIO_SECURE = os.getenv("MINIO_SECURE", "false").lower() == "true"

# Redis
REDIS_HOST = os.getenv("REDIS_HOST", "192.168.92.206")
REDIS_PORT = int(os.getenv("REDIS_PORT", "6379"))
REDIS_QUEUE = os.getenv("REDIS_QUEUE", "complaint_processing")

# Upload
ALLOWED_EXTENSIONS = os.getenv("ALLOWED_EXTENSIONS", ".pdf,.jpg,.jpeg,.png,.docx,.xlsx").split(",")
MAX_UPLOAD_SIZE = int(os.getenv("MAX_UPLOAD_SIZE", "52428800"))

# Log
LOG_DIR = os.getenv("LOG_DIR", "/var/log/minwon")
