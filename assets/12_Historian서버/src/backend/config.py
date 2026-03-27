"""
Historian 서버 설정 모듈
환경변수에서 InfluxDB 접속 정보를 로드한다.
"""

from pydantic_settings import BaseSettings
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """애플리케이션 설정"""

    HISTORIAN_API: str = "http://192.168.200.10:8000"
    INFLUXDB_URL: str = "http://192.168.200.10:8086"
    INFLUXDB_TOKEN: str = "historian-dev-token-2024"
    INFLUXDB_ORG: str = "ot-org"
    INFLUXDB_BUCKET: str = "ot_data"
    SCADA_HOST: str = "192.168.201.10"
    SCADA_PORT: int = 502

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
