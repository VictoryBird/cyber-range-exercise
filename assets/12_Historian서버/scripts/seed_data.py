#!/usr/bin/env python3
"""
Historian 시드 데이터 생성 스크립트
24시간 분량의 현실적인 센서 데이터를 InfluxDB에 삽입한다.

센서 범위:
  - temperature: 20~30 °C
  - pressure:    95~105 bar
  - flow_rate:   120~180 L/min (150 ± 30)
  - power:       220~240 V
"""

import os
import sys
import random
import math
from datetime import datetime, timedelta, timezone

from dotenv import load_dotenv
from influxdb_client import InfluxDBClient, Point
from influxdb_client.client.write_api import SYNCHRONOUS

# .env 로드
load_dotenv(os.path.join(os.path.dirname(__file__), "..", ".env.example"))
# docker-compose 환경에서는 환경변수가 우선
INFLUXDB_URL = os.getenv("INFLUXDB_URL", "http://localhost:8086")
INFLUXDB_TOKEN = os.getenv("INFLUXDB_TOKEN", "historian-dev-token-2024")
INFLUXDB_ORG = os.getenv("INFLUXDB_ORG", "ot-org")
INFLUXDB_BUCKET = os.getenv("INFLUXDB_BUCKET", "ot_data")

# 센서 정의: (base, amplitude, noise_std)
SENSORS = {
    "temperature": {"base": 25.0, "amplitude": 3.0, "noise": 0.5, "unit": "°C"},
    "pressure": {"base": 100.0, "amplitude": 3.0, "noise": 0.8, "unit": "bar"},
    "flow_rate": {"base": 150.0, "amplitude": 15.0, "noise": 3.0, "unit": "L/min"},
    "power": {"base": 230.0, "amplitude": 5.0, "noise": 1.0, "unit": "V"},
}

# 24시간, 30초 간격 = 2880 포인트/센서
DURATION_HOURS = 24
INTERVAL_SECONDS = 30


def generate_value(sensor_cfg: dict, t_fraction: float) -> float:
    """
    현실적인 센서 값을 생성한다.
    t_fraction: 0.0~1.0 (24시간 내 위치)

    일주기 패턴(사인파) + 가우시안 노이즈로 현실적 변동 모사.
    """
    base = sensor_cfg["base"]
    amplitude = sensor_cfg["amplitude"]
    noise = sensor_cfg["noise"]

    # 일주기 사인파 (낮에 높고 밤에 낮음)
    cyclic = amplitude * math.sin(2 * math.pi * t_fraction - math.pi / 2)

    # 가우시안 노이즈
    jitter = random.gauss(0, noise)

    return round(base + cyclic + jitter, 2)


def main():
    print(f"[*] InfluxDB 연결: {INFLUXDB_URL}")
    print(f"[*] Org: {INFLUXDB_ORG}, Bucket: {INFLUXDB_BUCKET}")

    client = InfluxDBClient(url=INFLUXDB_URL, token=INFLUXDB_TOKEN, org=INFLUXDB_ORG)

    # 연결 확인
    try:
        health = client.health()
        if health.status != "pass":
            print(f"[!] InfluxDB 상태 비정상: {health.status}")
            sys.exit(1)
        print(f"[+] InfluxDB 연결 성공 (status={health.status})")
    except Exception as e:
        print(f"[!] InfluxDB 연결 실패: {e}")
        sys.exit(1)

    write_api = client.write_api(write_options=SYNCHRONOUS)

    now = datetime.now(timezone.utc)
    start_time = now - timedelta(hours=DURATION_HOURS)
    total_points = DURATION_HOURS * 3600 // INTERVAL_SECONDS  # 2880

    print(f"[*] 시드 데이터 생성: {start_time.isoformat()} ~ {now.isoformat()}")
    print(f"[*] 센서 {len(SENSORS)}개 × {total_points} 포인트 = {len(SENSORS) * total_points} 레코드")

    for sensor_name, sensor_cfg in SENSORS.items():
        points = []
        for i in range(total_points):
            ts = start_time + timedelta(seconds=i * INTERVAL_SECONDS)
            t_fraction = i / total_points
            value = generate_value(sensor_cfg, t_fraction)

            point = (
                Point(sensor_name)
                .field("value", value)
                .time(ts)
            )
            points.append(point)

        # 배치 쓰기 (500개씩)
        batch_size = 500
        for batch_start in range(0, len(points), batch_size):
            batch = points[batch_start : batch_start + batch_size]
            write_api.write(bucket=INFLUXDB_BUCKET, org=INFLUXDB_ORG, record=batch)

        print(f"  [+] {sensor_name}: {len(points)} 포인트 삽입 완료")

    client.close()
    print(f"\n[+] 시드 데이터 생성 완료! 총 {len(SENSORS) * total_points} 레코드")


if __name__ == "__main__":
    main()
