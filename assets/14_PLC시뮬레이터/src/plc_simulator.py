#!/usr/bin/env python3
"""
PLC 시뮬레이터 -- OT 존 가상 센서 데이터 생성기
대상: 사이버 훈련 STEP 3-3
IP: 192.168.201.11:5000

의도적 취약점:
  VULN-14-01: 모든 API 엔드포인트 인증 없음
  VULN-14-02: /api/set_range 센서 출력 범위 조작 (검증 없음)
  VULN-14-03: /api/inject 임의 값 주입
  VULN-14-04: /api/config 내부 설정 노출
"""

import math
import os
import time
import random
import threading
from datetime import datetime, timedelta
from collections import deque

from flask import Flask, request, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# ---------------------------------------------------------------------------
# 환경 변수에서 설정 로드
# ---------------------------------------------------------------------------
PLC_HOST = os.getenv("PLC_HOST", "0.0.0.0")
PLC_PORT = int(os.getenv("PLC_PORT", "5000"))
UPDATE_INTERVAL = float(os.getenv("UPDATE_INTERVAL", "1.0"))
HISTORY_MAXLEN = int(os.getenv("HISTORY_MAXLEN", "3600"))

# ---------------------------------------------------------------------------
# 센서 설정 (기본값)
# ---------------------------------------------------------------------------
SENSOR_CONFIG = {
    "temperature": {
        "base_min": float(os.getenv("TEMP_MIN", "20.0")),
        "base_max": float(os.getenv("TEMP_MAX", "30.0")),
        "current_min": float(os.getenv("TEMP_MIN", "20.0")),
        "current_max": float(os.getenv("TEMP_MAX", "30.0")),
        "unit": "C",
        "noise_factor": 0.5,
        "wave_period": 300,
        "update_interval": UPDATE_INTERVAL,
    },
    "pressure": {
        "base_min": float(os.getenv("PRESSURE_MIN", "95.0")),
        "base_max": float(os.getenv("PRESSURE_MAX", "105.0")),
        "current_min": float(os.getenv("PRESSURE_MIN", "95.0")),
        "current_max": float(os.getenv("PRESSURE_MAX", "105.0")),
        "unit": "bar",
        "noise_factor": 1.0,
        "spike_probability": 0.02,
        "update_interval": UPDATE_INTERVAL,
    },
    "flow_rate": {
        "base_min": float(os.getenv("FLOW_RATE_MIN", "120.0")),
        "base_max": float(os.getenv("FLOW_RATE_MAX", "180.0")),
        "current_min": float(os.getenv("FLOW_RATE_MIN", "120.0")),
        "current_max": float(os.getenv("FLOW_RATE_MAX", "180.0")),
        "unit": "L/min",
        "noise_factor": 5.0,
        "cycle_period": 600,
        "update_interval": UPDATE_INTERVAL,
    },
    "power": {
        "base_min": float(os.getenv("POWER_MIN", "220.0")),
        "base_max": float(os.getenv("POWER_MAX", "240.0")),
        "current_min": float(os.getenv("POWER_MIN", "220.0")),
        "current_max": float(os.getenv("POWER_MAX", "240.0")),
        "unit": "V",
        "noise_factor": 2.0,
        "daily_cycle": True,
        "update_interval": UPDATE_INTERVAL,
    },
}

# ---------------------------------------------------------------------------
# 글로벌 상태
# ---------------------------------------------------------------------------
sensor_values = {
    "temperature": 25.0,
    "pressure": 100.0,
    "flow_rate": 150.0,
    "power": 230.0,
}

# 이력 저장 (센서별 최근 HISTORY_MAXLEN개)
sensor_history = {
    "temperature": deque(maxlen=HISTORY_MAXLEN),
    "pressure": deque(maxlen=HISTORY_MAXLEN),
    "flow_rate": deque(maxlen=HISTORY_MAXLEN),
    "power": deque(maxlen=HISTORY_MAXLEN),
}

# 값 주입 상태
injection_state = {
    "active": False,
    "sensor": None,
    "value": None,
    "expires_at": None,
}

start_time = time.time()


# ---------------------------------------------------------------------------
# 센서 시뮬레이션 함수
# ---------------------------------------------------------------------------

def simulate_temperature(t: float) -> float:
    """
    온도 시뮬레이션: 사인파(20-30 C) + 가우시안 노이즈
    주기: 300초
    """
    cfg = SENSOR_CONFIG["temperature"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    base = mid + amp * math.sin(2 * math.pi * t / cfg["wave_period"])
    noise = random.gauss(0, cfg["noise_factor"])

    value = base + noise
    return round(value, 2)


def simulate_pressure(t: float) -> float:
    """
    압력 시뮬레이션: 안정값(95-105 bar) + 간헐적 스파이크(2% 확률)
    """
    cfg = SENSOR_CONFIG["pressure"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    base = mid + amp * 0.3 * math.sin(2 * math.pi * t / 120)
    noise = random.gauss(0, cfg["noise_factor"])

    # 간헐적 스파이크 (2% 확률)
    spike = 0
    if random.random() < cfg.get("spike_probability", 0.02):
        spike = random.choice([-1, 1]) * random.uniform(2, 5)

    value = base + noise + spike
    value = max(cfg["current_min"] - 5, min(cfg["current_max"] + 5, value))
    return round(value, 2)


def simulate_flow_rate(t: float) -> float:
    """
    유량 시뮬레이션: 주기적 패턴(150 +/- 30 L/min) + 2차 고조파 + 노이즈
    주기: 600초
    """
    cfg = SENSOR_CONFIG["flow_rate"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2
    period = cfg.get("cycle_period", 600)

    cycle = amp * 0.6 * math.sin(2 * math.pi * t / period)
    harmonic = amp * 0.2 * math.sin(4 * math.pi * t / period)
    noise = random.gauss(0, cfg["noise_factor"])

    value = mid + cycle + harmonic + noise
    value = max(cfg["current_min"] * 0.8, min(cfg["current_max"] * 1.2, value))
    return round(value, 2)


def simulate_power(t: float) -> float:
    """
    전압 시뮬레이션: 일간 부하 패턴(220-240 V) + 고주파 리플 + 노이즈
    낮 시간대(9-18시) 부하 증가로 전압 약간 하락
    """
    cfg = SENSOR_CONFIG["power"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    # 일간 부하 사이클 (24시간 = 86400초)
    hour_of_day = (time.time() % 86400) / 3600

    # 부하 패턴: 9-18시 고부하 -> 전압 약간 하락
    if 9 <= hour_of_day <= 18:
        load_factor = -0.3
    else:
        load_factor = 0.2

    base = mid + amp * load_factor

    # 고주파 변동 (전력 리플)
    ripple = amp * 0.1 * math.sin(2 * math.pi * t / 10)

    noise = random.gauss(0, cfg["noise_factor"])

    value = base + ripple + noise
    value = max(cfg["current_min"] - 5, min(cfg["current_max"] + 5, value))
    return round(value, 2)


# 시뮬레이션 함수 매핑
SIMULATORS = {
    "temperature": simulate_temperature,
    "pressure": simulate_pressure,
    "flow_rate": simulate_flow_rate,
    "power": simulate_power,
}


def sensor_update_loop():
    """백그라운드 스레드: UPDATE_INTERVAL마다 모든 센서 값 업데이트"""
    while True:
        t = time.time() - start_time
        now = datetime.now().isoformat()

        for sensor_name, simulator_func in SIMULATORS.items():
            # 값 주입이 활성화된 경우 해당 센서는 주입값 사용
            if (
                injection_state["active"]
                and injection_state["sensor"] == sensor_name
                and injection_state["expires_at"]
                and datetime.now() < injection_state["expires_at"]
            ):
                value = injection_state["value"]
            else:
                # 주입 만료 확인
                if (
                    injection_state["active"]
                    and injection_state["sensor"] == sensor_name
                ):
                    injection_state["active"] = False
                    injection_state["sensor"] = None
                    injection_state["value"] = None
                    injection_state["expires_at"] = None

                value = simulator_func(t)

            sensor_values[sensor_name] = value
            sensor_history[sensor_name].append(
                {"timestamp": now, "value": value}
            )

        time.sleep(UPDATE_INTERVAL)


# ---------------------------------------------------------------------------
# API 엔드포인트
# ---------------------------------------------------------------------------


# [취약점] VULN-14-01: 모든 API 엔드포인트에 인증이 없음
# 올바른 구현: Flask-Login 또는 API 키 인증을 적용하여
# 인가된 SCADA 서버(192.168.201.10)만 접근 허용해야 함


@app.route("/api/status", methods=["GET"])
def get_status():
    """
    현재 모든 센서 값 반환
    [취약점] VULN-14-01: 인증 없이 센서 데이터 접근 가능
    올바른 구현: API 키 또는 IP 화이트리스트 적용 필요
    """
    sensors = {}
    for name, value in sensor_values.items():
        cfg = SENSOR_CONFIG[name]
        sensors[name] = {
            "value": value,
            "unit": cfg["unit"],
            "min_range": cfg["current_min"],
            "max_range": cfg["current_max"],
            "status": _get_sensor_status(name, value),
        }

    return jsonify(
        {
            "timestamp": datetime.now().isoformat(),
            "uptime_seconds": int(time.time() - start_time),
            "sensors": sensors,
        }
    )


@app.route("/api/config", methods=["GET"])
def get_config():
    """
    센서 설정 정보 반환
    [취약점] VULN-14-04: 내부 센서 설정(범위, 노이즈 팩터, 주기 등)이
    인증 없이 노출됨. 공격자가 정밀 공격을 위한 정찰에 활용 가능.
    올바른 구현: 관리자 인증 필요, 민감 설정은 응답에서 제외해야 함
    """
    config_export = {}
    for name, cfg in SENSOR_CONFIG.items():
        config_export[name] = {k: v for k, v in cfg.items()}

    return jsonify(
        {
            "sensors": config_export,
            "injection_active": injection_state["active"],
            "injection_details": (
                {
                    "sensor": injection_state["sensor"],
                    "value": injection_state["value"],
                    "expires_at": (
                        injection_state["expires_at"].isoformat()
                        if injection_state["expires_at"]
                        else None
                    ),
                }
                if injection_state["active"]
                else None
            ),
        }
    )


@app.route("/api/set_range", methods=["POST"])
def set_range():
    """
    센서 출력 범위 변경
    [취약점] VULN-14-02: 인증 없음 + 입력값 검증 없음
    공격 시나리오: 범위를 좁혀서 위험값이 정상으로 보이게 하거나,
    넓혀서 실제 이상 상태가 탐지되지 않게 함.
    올바른 구현: (1) 관리자 인증 필요
                (2) base_min/base_max 범위를 벗어나는 값 거부
                (3) min < max 검증
                (4) 변경 이력 로깅
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    sensor = data.get("sensor")
    new_min = data.get("min")
    new_max = data.get("max")

    if sensor not in SENSOR_CONFIG:
        return jsonify({"error": f"Unknown sensor: {sensor}"}), 400

    # [취약점] VULN-14-02: 입력값 검증 없음 — 어떤 범위든 설정 가능
    # 올바른 구현: base_min <= new_min < new_max <= base_max 검증 필요
    cfg = SENSOR_CONFIG[sensor]
    previous = {"min": cfg["current_min"], "max": cfg["current_max"]}

    cfg["current_min"] = (
        float(new_min) if new_min is not None else cfg["current_min"]
    )
    cfg["current_max"] = (
        float(new_max) if new_max is not None else cfg["current_max"]
    )

    return jsonify(
        {
            "status": "success",
            "sensor": sensor,
            "previous_range": previous,
            "new_range": {"min": cfg["current_min"], "max": cfg["current_max"]},
            "message": "Range updated successfully",
        }
    )


@app.route("/api/inject", methods=["POST"])
def inject_value():
    """
    특정 센서에 값 강제 주입
    [취약점] VULN-14-03: 인증 없음 + 입력값 검증 없음
    공격 시나리오: 정상값을 주입하여 실제 이상 상태를 SCADA에서 은닉.
    올바른 구현: (1) 관리자 인증 필요
                (2) 주입 기능 자체를 프로덕션에서 비활성화
                (3) 허용 범위 내 값만 주입 가능하도록 제한
                (4) 주입 이벤트 로깅 및 알림
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    sensor = data.get("sensor")
    value = data.get("value")
    duration = data.get("duration", 60)  # 기본 60초

    if sensor not in SENSOR_CONFIG:
        return jsonify({"error": f"Unknown sensor: {sensor}"}), 400

    if value is None:
        return jsonify({"error": "value is required"}), 400

    # [취약점] VULN-14-03: 어떤 값이든 주입 가능, 검증 없음
    # 올바른 구현: base_min <= value <= base_max 검증, duration 상한 설정
    expires_at = datetime.now() + timedelta(seconds=int(duration))
    injection_state["active"] = True
    injection_state["sensor"] = sensor
    injection_state["value"] = float(value)
    injection_state["expires_at"] = expires_at

    return jsonify(
        {
            "status": "success",
            "sensor": sensor,
            "injected_value": float(value),
            "duration_seconds": int(duration),
            "expires_at": expires_at.isoformat(),
            "message": "Value injection active",
        }
    )


@app.route("/api/history", methods=["GET"])
def get_history():
    """
    최근 센서 측정 이력 반환
    [취약점] VULN-14-01: 인증 없이 이력 데이터 접근 가능
    올바른 구현: API 키 인증 적용 필요
    """
    sensor = request.args.get("sensor", "temperature")
    count = int(request.args.get("count", 100))

    if sensor not in sensor_history:
        return jsonify({"error": f"Unknown sensor: {sensor}"}), 400

    history = list(sensor_history[sensor])
    readings = history[-count:] if len(history) > count else history

    return jsonify(
        {"sensor": sensor, "count": len(readings), "readings": readings}
    )


@app.route("/api/health", methods=["GET"])
def health_check():
    """서비스 상태 확인"""
    return jsonify(
        {
            "status": "healthy",
            "version": "1.0.0",
            "uptime_seconds": int(time.time() - start_time),
            "sensors_active": len(sensor_values),
        }
    )


def _get_sensor_status(name: str, value: float) -> str:
    """센서 상태 판별 (normal / warning / critical)"""
    cfg = SENSOR_CONFIG[name]
    base_min = cfg["base_min"]
    base_max = cfg["base_max"]

    if base_min <= value <= base_max:
        return "normal"
    elif (base_min - 5) <= value <= (base_max + 5):
        return "warning"
    else:
        return "critical"


# ---------------------------------------------------------------------------
# Gunicorn 호환: 워커 시작 시 백그라운드 스레드 자동 실행
# ---------------------------------------------------------------------------
_thread_started = False


def start_background_thread():
    global _thread_started
    if not _thread_started:
        update_thread = threading.Thread(target=sensor_update_loop, daemon=True)
        update_thread.start()
        _thread_started = True


# 앱 로딩 시 스레드 시작
start_background_thread()


# ---------------------------------------------------------------------------
# 메인 실행
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("=" * 60)
    print("PLC 시뮬레이터 시작")
    print(f"  API: http://{PLC_HOST}:{PLC_PORT}")
    print(f"  센서: {', '.join(SENSOR_CONFIG.keys())}")
    print(f"  경고: 인증 없이 모든 API 접근 가능 (훈련용)")
    print("=" * 60)

    app.run(host=PLC_HOST, port=PLC_PORT, debug=False)
