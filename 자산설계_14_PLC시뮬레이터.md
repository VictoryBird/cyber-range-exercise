# 자산 설계서: #14 PLC 시뮬레이터

| 항목 | 내용 |
|------|------|
| 자산 ID | #14 |
| IP | 192.168.201.11 |
| OS | Ubuntu 22.04 LTS |
| 호스트명 | plc-simulator |
| 도메인 | plc-simulator.ot.local |
| 역할 | 가상 센서 데이터 생성 (PLC 시뮬레이터) |
| 네트워크 존 | OT (192.168.201.0/24) |
| 방화벽 | OPNSense-5 |
| 훈련 단계 | STEP 3-3 |
| 작성일 | 2026-03-26 |

---

## 1. 개요

PLC 시뮬레이터는 실제 PLC(Programmable Logic Controller) 장비를 대체하는 소프트웨어 기반 가상 센서 데이터 생성기이다. 산업 공정에서 발생하는 4종류의 센서 데이터(온도, 압력, 유량, 전압)를 현실적인 패턴으로 생성하며, REST API를 통해 데이터를 노출한다.

**핵심 특징:**
- 실제 공정 데이터를 모사하는 수학적 시뮬레이션 (사인파 + 노이즈)
- 인증 없이 접근 가능한 REST API (의도적 취약점)
- 센서 출력 범위 조작 및 값 주입 기능 제공

| 항목 | 값 |
|------|-----|
| IP | 192.168.201.11 |
| OS | Ubuntu 22.04 LTS |
| 서비스 포트 | TCP 5000 |
| 역할 | 가상 센서 데이터 생성 |
| 훈련 단계 | STEP 3-3 |

## 2. 기술 스택

| 계층 | 기술 | 버전 | 비고 |
|------|------|------|------|
| OS | Ubuntu | 22.04 LTS | Server 에디션 |
| Language | Python | 3.11 | 시뮬레이션 로직 |
| Web Framework | Flask | 3.0.x | REST API 서버 |
| WSGI | Gunicorn | 21.x | 프로덕션 서버 |
| 의존성 | NumPy | 1.26.x | 수학 연산 |

## 3. API 명세

### 전체 엔드포인트 목록

| Method | Endpoint | 인증 | 설명 | 위험도 |
|--------|----------|------|------|--------|
| GET | /api/status | 없음 | 현재 전체 센서 값 조회 | 낮음 |
| GET | /api/config | 없음 | 센서 설정(범위, 주기) 조회 | 중간 |
| POST | /api/set_range | **없음** | 센서 출력 범위 변경 | **높음** |
| POST | /api/inject | **없음** | 특정 값 강제 주입 | **높음** |
| GET | /api/history | 없음 | 최근 측정 이력 조회 | 낮음 |
| GET | /api/health | 없음 | 서비스 상태 확인 | 낮음 |

### API 상세

**GET /api/status**

현재 모든 센서의 실시간 값을 반환한다.

```
요청: GET http://192.168.201.11:5000/api/status
인증: 없음

응답 (200 OK):
{
    "timestamp": "2026-03-26T14:30:05.123456",
    "uptime_seconds": 86400,
    "sensors": {
        "temperature": {
            "value": 25.3,
            "unit": "C",
            "min_range": 20.0,
            "max_range": 30.0,
            "status": "normal"
        },
        "pressure": {
            "value": 100.2,
            "unit": "bar",
            "min_range": 95.0,
            "max_range": 105.0,
            "status": "normal"
        },
        "flow_rate": {
            "value": 148.5,
            "unit": "L/min",
            "min_range": 120.0,
            "max_range": 180.0,
            "status": "normal"
        },
        "power": {
            "value": 231.0,
            "unit": "V",
            "min_range": 220.0,
            "max_range": 240.0,
            "status": "normal"
        }
    }
}
```

**GET /api/config**

센서 설정 정보를 노출한다 (취약점: 내부 설정이 인증 없이 열람 가능).

```
요청: GET http://192.168.201.11:5000/api/config
인증: 없음

응답 (200 OK):
{
    "sensors": {
        "temperature": {
            "base_min": 20.0,
            "base_max": 30.0,
            "current_min": 20.0,
            "current_max": 30.0,
            "noise_factor": 0.5,
            "wave_period": 300,
            "update_interval": 1.0
        },
        "pressure": {
            "base_min": 95.0,
            "base_max": 105.0,
            "current_min": 95.0,
            "current_max": 105.0,
            "noise_factor": 1.0,
            "spike_probability": 0.02,
            "update_interval": 1.0
        },
        "flow_rate": {
            "base_min": 120.0,
            "base_max": 180.0,
            "current_min": 120.0,
            "current_max": 180.0,
            "noise_factor": 5.0,
            "cycle_period": 600,
            "update_interval": 1.0
        },
        "power": {
            "base_min": 220.0,
            "base_max": 240.0,
            "current_min": 220.0,
            "current_max": 240.0,
            "noise_factor": 2.0,
            "daily_cycle": true,
            "update_interval": 1.0
        }
    },
    "injection_active": false,
    "injection_details": null
}
```

**POST /api/set_range (취약)**

센서 출력 범위를 변경한다. 입력값 검증 없음.

```
요청: POST http://192.168.201.11:5000/api/set_range
Content-Type: application/json

{
    "sensor": "temperature",
    "min": 24.0,
    "max": 26.0
}

응답 (200 OK):
{
    "status": "success",
    "sensor": "temperature",
    "previous_range": {"min": 20.0, "max": 30.0},
    "new_range": {"min": 24.0, "max": 26.0},
    "message": "Range updated successfully"
}
```

**공격 예시 -- 위험 상태를 정상으로 보이게 함:**

```bash
# 온도 범위를 극도로 넓혀서 50도가 나와도 "정상"으로 보이게
curl -X POST http://192.168.201.11:5000/api/set_range \
  -H "Content-Type: application/json" \
  -d '{"sensor": "temperature", "min": 24.5, "max": 25.5}'
# 이제 온도는 항상 24.5~25.5 사이로만 보고됨 (실제 위험 상태 은닉)
```

**POST /api/inject (취약)**

특정 센서에 원하는 값을 일정 시간 동안 강제 주입한다.

```
요청: POST http://192.168.201.11:5000/api/inject
Content-Type: application/json

{
    "sensor": "temperature",
    "value": 25.0,
    "duration": 300
}

응답 (200 OK):
{
    "status": "success",
    "sensor": "temperature",
    "injected_value": 25.0,
    "duration_seconds": 300,
    "expires_at": "2026-03-26T14:35:05.000000",
    "message": "Value injection active"
}
```

**GET /api/history**

최근 센서 측정 이력을 반환한다.

```
요청: GET http://192.168.201.11:5000/api/history?sensor=temperature&count=10
인증: 없음

응답 (200 OK):
{
    "sensor": "temperature",
    "count": 10,
    "readings": [
        {"timestamp": "2026-03-26T14:30:05", "value": 25.3},
        {"timestamp": "2026-03-26T14:30:04", "value": 25.1},
        {"timestamp": "2026-03-26T14:30:03", "value": 25.4},
        ...
    ]
}
```

**GET /api/health**

```
요청: GET http://192.168.201.11:5000/api/health

응답 (200 OK):
{
    "status": "healthy",
    "version": "1.0.0",
    "uptime_seconds": 86400,
    "sensors_active": 4
}
```

## 4. 센서 시뮬레이션 로직

### 4-1. 전체 소스 코드 (plc_simulator.py)

```python
#!/usr/bin/env python3
"""
PLC 시뮬레이터 -- OT 존 가상 센서 데이터 생성기
대상: 사이버 훈련 STEP 3-3
IP: 192.168.201.11:5000

의도적 취약점:
  - 모든 API 엔드포인트 인증 없음
  - /api/set_range: 센서 출력 범위 조작 가능
  - /api/inject: 임의 값 주입 가능
  - 입력값 검증 없음
"""

import math
import time
import random
import threading
from datetime import datetime, timedelta
from collections import deque
from flask import Flask, request, jsonify

app = Flask(__name__)

# ---------------------------------------------------------------------------
# 센서 설정 (기본값)
# ---------------------------------------------------------------------------
SENSOR_CONFIG = {
    "temperature": {
        "base_min": 20.0,       # 기본 최소값 (C)
        "base_max": 30.0,       # 기본 최대값 (C)
        "current_min": 20.0,    # 현재 최소값 (조작 가능)
        "current_max": 30.0,    # 현재 최대값 (조작 가능)
        "unit": "C",
        "noise_factor": 0.5,    # 무작위 노이즈 크기
        "wave_period": 300,     # 사인파 주기 (초)
        "update_interval": 1.0  # 업데이트 간격 (초)
    },
    "pressure": {
        "base_min": 95.0,       # 기본 최소값 (bar)
        "base_max": 105.0,      # 기본 최대값 (bar)
        "current_min": 95.0,
        "current_max": 105.0,
        "unit": "bar",
        "noise_factor": 1.0,
        "spike_probability": 0.02,  # 스파이크 발생 확률 (2%)
        "update_interval": 1.0
    },
    "flow_rate": {
        "base_min": 120.0,      # 기본 최소값 (L/min)
        "base_max": 180.0,      # 기본 최대값 (L/min)
        "current_min": 120.0,
        "current_max": 180.0,
        "unit": "L/min",
        "noise_factor": 5.0,
        "cycle_period": 600,    # 주기적 패턴 (초)
        "update_interval": 1.0
    },
    "power": {
        "base_min": 220.0,      # 기본 최소값 (V)
        "base_max": 240.0,      # 기본 최대값 (V)
        "current_min": 220.0,
        "current_max": 240.0,
        "unit": "V",
        "noise_factor": 2.0,
        "daily_cycle": True,    # 일간 부하 패턴
        "update_interval": 1.0
    }
}

# ---------------------------------------------------------------------------
# 글로벌 상태
# ---------------------------------------------------------------------------
sensor_values = {
    "temperature": 25.0,
    "pressure": 100.0,
    "flow_rate": 150.0,
    "power": 230.0
}

# 이력 저장 (센서별 최근 3600개 = 1시간 분량)
sensor_history = {
    "temperature": deque(maxlen=3600),
    "pressure": deque(maxlen=3600),
    "flow_rate": deque(maxlen=3600),
    "power": deque(maxlen=3600)
}

# 값 주입 상태
injection_state = {
    "active": False,
    "sensor": None,
    "value": None,
    "expires_at": None
}

start_time = time.time()

# ---------------------------------------------------------------------------
# 센서 시뮬레이션 함수
# ---------------------------------------------------------------------------

def simulate_temperature(t: float) -> float:
    """
    온도 시뮬레이션: 사인파 + 무작위 노이즈
    기본 범위: 20-30 C
    패턴: 느린 사인파로 자연스러운 온도 변화 모사
    """
    cfg = SENSOR_CONFIG["temperature"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    # 기본 사인파 (주기: wave_period초)
    base = mid + amp * math.sin(2 * math.pi * t / cfg["wave_period"])

    # 무작위 노이즈 추가
    noise = random.gauss(0, cfg["noise_factor"])

    value = base + noise
    return round(value, 2)


def simulate_pressure(t: float) -> float:
    """
    압력 시뮬레이션: 정상 상태 + 간헐적 스파이크
    기본 범위: 95-105 bar
    패턴: 안정적이지만 가끔 급격한 변동 발생
    """
    cfg = SENSOR_CONFIG["pressure"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    # 기본 값 (중심값 근처에서 소폭 변동)
    base = mid + amp * 0.3 * math.sin(2 * math.pi * t / 120)

    # 무작위 노이즈
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
    유량 시뮬레이션: 주기적 패턴 (공정 사이클 반영)
    기본 범위: 120-180 L/min (중심값 150 +/- 30)
    패턴: 느린 사이클로 공정 운전 패턴 모사
    """
    cfg = SENSOR_CONFIG["flow_rate"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    # 주기적 패턴 (cycle_period초 주기)
    cycle = amp * 0.6 * math.sin(2 * math.pi * t / cfg.get("cycle_period", 600))

    # 2차 고조파 추가 (더 현실적인 패턴)
    harmonic = amp * 0.2 * math.sin(4 * math.pi * t / cfg.get("cycle_period", 600))

    # 무작위 노이즈
    noise = random.gauss(0, cfg["noise_factor"])

    value = mid + cycle + harmonic + noise
    value = max(cfg["current_min"] * 0.8, min(cfg["current_max"] * 1.2, value))
    return round(value, 2)


def simulate_power(t: float) -> float:
    """
    전압 시뮬레이션: 일간 부하 패턴
    기본 범위: 220-240 V
    패턴: 낮 시간대 부하 증가로 전압 변동
    """
    cfg = SENSOR_CONFIG["power"]
    mid = (cfg["current_min"] + cfg["current_max"]) / 2
    amp = (cfg["current_max"] - cfg["current_min"]) / 2

    # 일간 부하 사이클 (24시간 = 86400초)
    hour_of_day = (time.time() % 86400) / 3600  # 현재 시각 (0-24)

    # 부하 패턴: 9-18시에 높은 부하 -> 전압 약간 하락
    if 9 <= hour_of_day <= 18:
        load_factor = -0.3  # 부하 시간대: 전압 약간 낮음
    else:
        load_factor = 0.2   # 저부하 시간대: 전압 약간 높음

    base = mid + amp * load_factor

    # 고주파 변동 (전력 노이즈)
    ripple = amp * 0.1 * math.sin(2 * math.pi * t / 10)

    # 무작위 노이즈
    noise = random.gauss(0, cfg["noise_factor"])

    value = base + ripple + noise
    value = max(cfg["current_min"] - 5, min(cfg["current_max"] + 5, value))
    return round(value, 2)


# 시뮬레이션 함수 매핑
SIMULATORS = {
    "temperature": simulate_temperature,
    "pressure": simulate_pressure,
    "flow_rate": simulate_flow_rate,
    "power": simulate_power
}


def sensor_update_loop():
    """백그라운드 스레드: 1초마다 모든 센서 값 업데이트"""
    while True:
        t = time.time() - start_time
        now = datetime.now().isoformat()

        for sensor_name, simulator_func in SIMULATORS.items():
            # 값 주입이 활성화된 경우 해당 센서는 주입값 사용
            if (injection_state["active"]
                    and injection_state["sensor"] == sensor_name
                    and injection_state["expires_at"]
                    and datetime.now() < injection_state["expires_at"]):
                value = injection_state["value"]
            else:
                # 주입 만료 확인
                if (injection_state["active"]
                        and injection_state["sensor"] == sensor_name):
                    injection_state["active"] = False
                    injection_state["sensor"] = None
                    injection_state["value"] = None
                    injection_state["expires_at"] = None

                value = simulator_func(t)

            sensor_values[sensor_name] = value
            sensor_history[sensor_name].append({
                "timestamp": now,
                "value": value
            })

        time.sleep(1)


# ---------------------------------------------------------------------------
# API 엔드포인트
# ---------------------------------------------------------------------------

@app.route("/api/status", methods=["GET"])
def get_status():
    """현재 모든 센서 값 반환"""
    sensors = {}
    for name, value in sensor_values.items():
        cfg = SENSOR_CONFIG[name]
        sensors[name] = {
            "value": value,
            "unit": cfg["unit"],
            "min_range": cfg["current_min"],
            "max_range": cfg["current_max"],
            "status": _get_sensor_status(name, value)
        }

    return jsonify({
        "timestamp": datetime.now().isoformat(),
        "uptime_seconds": int(time.time() - start_time),
        "sensors": sensors
    })


@app.route("/api/config", methods=["GET"])
def get_config():
    """
    센서 설정 정보 반환
    취약점: 내부 설정이 인증 없이 노출됨
    """
    config_export = {}
    for name, cfg in SENSOR_CONFIG.items():
        config_export[name] = {k: v for k, v in cfg.items()}

    return jsonify({
        "sensors": config_export,
        "injection_active": injection_state["active"],
        "injection_details": {
            "sensor": injection_state["sensor"],
            "value": injection_state["value"],
            "expires_at": (injection_state["expires_at"].isoformat()
                          if injection_state["expires_at"] else None)
        } if injection_state["active"] else None
    })


@app.route("/api/set_range", methods=["POST"])
def set_range():
    """
    센서 출력 범위 변경
    취약점: 인증 없음, 입력값 검증 없음
    공격 시나리오: 범위를 좁혀서 위험 값이 정상으로 보이게 함
    """
    data = request.get_json()
    if not data:
        return jsonify({"error": "JSON body required"}), 400

    sensor = data.get("sensor")
    new_min = data.get("min")
    new_max = data.get("max")

    if sensor not in SENSOR_CONFIG:
        return jsonify({"error": f"Unknown sensor: {sensor}"}), 400

    # 의도적 취약점: 입력값 검증 없음
    # 정상적이라면 여기서 범위 유효성 검사를 해야 함
    cfg = SENSOR_CONFIG[sensor]
    previous = {"min": cfg["current_min"], "max": cfg["current_max"]}

    cfg["current_min"] = float(new_min) if new_min is not None else cfg["current_min"]
    cfg["current_max"] = float(new_max) if new_max is not None else cfg["current_max"]

    return jsonify({
        "status": "success",
        "sensor": sensor,
        "previous_range": previous,
        "new_range": {"min": cfg["current_min"], "max": cfg["current_max"]},
        "message": "Range updated successfully"
    })


@app.route("/api/inject", methods=["POST"])
def inject_value():
    """
    특정 센서에 값 강제 주입
    취약점: 인증 없음, 입력값 검증 없음
    공격 시나리오: 정상 값을 주입하여 실제 이상 상태를 은닉
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

    # 의도적 취약점: 어떤 값이든 주입 가능, 검증 없음
    expires_at = datetime.now() + timedelta(seconds=int(duration))
    injection_state["active"] = True
    injection_state["sensor"] = sensor
    injection_state["value"] = float(value)
    injection_state["expires_at"] = expires_at

    return jsonify({
        "status": "success",
        "sensor": sensor,
        "injected_value": float(value),
        "duration_seconds": int(duration),
        "expires_at": expires_at.isoformat(),
        "message": "Value injection active"
    })


@app.route("/api/history", methods=["GET"])
def get_history():
    """최근 센서 측정 이력 반환"""
    sensor = request.args.get("sensor", "temperature")
    count = int(request.args.get("count", 60))

    if sensor not in sensor_history:
        return jsonify({"error": f"Unknown sensor: {sensor}"}), 400

    history = list(sensor_history[sensor])
    readings = history[-count:] if len(history) > count else history

    return jsonify({
        "sensor": sensor,
        "count": len(readings),
        "readings": readings
    })


@app.route("/api/health", methods=["GET"])
def health_check():
    """서비스 상태 확인"""
    return jsonify({
        "status": "healthy",
        "version": "1.0.0",
        "uptime_seconds": int(time.time() - start_time),
        "sensors_active": len(sensor_values)
    })


def _get_sensor_status(name: str, value: float) -> str:
    """센서 상태 판별 (정상/경고/위험)"""
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
# 메인 실행
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    # 센서 업데이트 백그라운드 스레드 시작
    update_thread = threading.Thread(target=sensor_update_loop, daemon=True)
    update_thread.start()

    print("=" * 60)
    print("PLC 시뮬레이터 시작")
    print(f"  API: http://0.0.0.0:5000")
    print(f"  센서: {', '.join(SENSOR_CONFIG.keys())}")
    print(f"  경고: 인증 없이 모든 API 접근 가능 (훈련용)")
    print("=" * 60)

    app.run(host="0.0.0.0", port=5000, debug=False)
```

### 4-2. 의존성 파일 (requirements.txt)

```
flask==3.0.2
gunicorn==21.2.0
numpy==1.26.4
```

### 4-3. 센서 데이터 생성 패턴 상세

```
+-- 온도 (temperature) -----------------------------------------------+
|  패턴: 사인파 + 가우시안 노이즈                                      |
|  수식: value = mid + amp * sin(2*pi*t/300) + gauss(0, 0.5)          |
|                                                                      |
|  30 |         ****                        ****                       |
|     |       **    **                    **    **                     |
|  25 |  ****        ****            ****        ****                  |
|     |**                **        **                **                |
|  20 |                    ********                    *               |
|     +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--> t(sec)       |
|     0  30  60  90 120 150 180 210 240 270 300 330 360                |
|     |<------------- 1 주기 (300초) ------------->|                    |
+----------------------------------------------------------------------+

+-- 압력 (pressure) --------------------------------------------------+
|  패턴: 안정값 + 간헐적 스파이크 (2% 확률)                            |
|  수식: value = mid + 0.3*amp*sin(2*pi*t/120) + gauss(0,1) + spike   |
|                                                                      |
| 110 |                     *                                          |
| 105 |                     *                                          |
| 100 | ~~~~~~~~~~~~~~~~~~~*~*~~~~~~~~~~~~~~~~~~  <- 정상 범위         |
|  95 |                                                                |
|  90 |                                      *  <- 하향 스파이크       |
|     +--+--+--+--+--+--+--+--+--+--+--+--+--> t(sec)                |
+----------------------------------------------------------------------+

+-- 유량 (flow_rate) -------------------------------------------------+
|  패턴: 기본파 + 2차 고조파 + 노이즈                                  |
|  수식: mid + 0.6*amp*sin(2*pi*t/600) + 0.2*amp*sin(4*pi*t/600)     |
|                                                                      |
| 180 |     ***                                                        |
|     |   **   *                                                       |
| 150 | **      **          ***                                        |
|     |           **      **   **                                      |
| 120 |             ******       **                                    |
|     +--+--+--+--+--+--+--+--+--+--> t(sec)                         |
|     |<---------- 1 주기 (600초) -------->|                           |
+----------------------------------------------------------------------+

+-- 전압 (power) -----------------------------------------------------+
|  패턴: 일간 부하 패턴 + 고주파 리플 + 노이즈                         |
|                                                                      |
| 240 |*****                              *****  <- 저부하 (야간)      |
|     |     \                            /                             |
| 230 |      \          ~~~~~~~~~~~~    /        <- 고부하 (주간)      |
|     |       \________/            \__/                               |
| 220 |                                                                |
|     +--+--+--+--+--+--+--+--+--+--+--+--+--> 시간                  |
|     00  03  06  09  12  15  18  21  24                               |
|              |<-- 고부하 구간 -->|                                    |
+----------------------------------------------------------------------+
```

## 5. 의도적 취약점 (STEP 3-3)

### 취약점 목록

| ID | 취약점 | 심각도 | 공격 시나리오 |
|----|--------|--------|---------------|
| V-PLC-01 | 전체 API 인증 없음 | 높음 | 네트워크 접근만으로 모든 기능 사용 가능 |
| V-PLC-02 | /api/set_range 범위 조작 | 높음 | 센서 범위를 좁혀 위험값을 정상으로 위장 |
| V-PLC-03 | /api/inject 값 주입 | 높음 | 정상값을 강제 주입하여 실제 이상 은닉 |
| V-PLC-04 | /api/config 설정 노출 | 중간 | 내부 설정 정보 열람으로 정밀 공격 가능 |
| V-PLC-05 | 입력값 검증 없음 | 중간 | 비정상 값(음수, 극값) 주입 가능 |

### 공격 체인 (STEP 3-3 시나리오)

```
[1단계] 정찰
    $ curl http://192.168.201.11:5000/api/config
    -> 센서 설정, 범위, 주기 등 내부 정보 획득

[2단계] 범위 조작 (은밀한 공격)
    $ curl -X POST http://192.168.201.11:5000/api/set_range \
        -H "Content-Type: application/json" \
        -d '{"sensor":"temperature","min":24.5,"max":25.5}'
    -> 온도가 항상 24.5~25.5 사이로만 보고됨
    -> SCADA에서는 "정상"으로 표시됨
    -> 실제로 위험한 온도여도 운영자가 인지하지 못함

[3단계] 값 주입 (적극적 공격)
    $ curl -X POST http://192.168.201.11:5000/api/inject \
        -H "Content-Type: application/json" \
        -d '{"sensor":"pressure","value":100.0,"duration":600}'
    -> 압력이 10분간 100.0bar로 고정
    -> 실제 압력이 위험 수준이어도 SCADA에는 100.0bar로 표시

[4단계] 결합 공격 (SCADA + PLC 동시)
    # PLC에서 데이터 조작 + SCADA에서 알람 임계값 변경
    -> 운영자는 완전히 잘못된 정보에 기반하여 판단
    -> "정상" 상태로 보이지만 실제로는 위험 상태
```

## 6. 설치/구성 절차

### setup.sh

```bash
#!/bin/bash
# plc_simulator_setup.sh - PLC 시뮬레이터 설치
# 대상: 192.168.201.11 (Ubuntu 22.04)

set -euo pipefail

echo "=== [1/5] 시스템 기본 설정 ==="
hostnamectl set-hostname plc-simulator

cat > /etc/netplan/01-static.yaml << 'NETEOF'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens192:
      addresses:
        - 192.168.201.11/24
      routes:
        - to: default
          via: 192.168.201.1
      nameservers:
        addresses:
          - 192.168.201.1
NETEOF
netplan apply

echo "=== [2/5] Python 3.11 설치 ==="
apt-get update
apt-get install -y python3.11 python3.11-venv python3-pip

echo "=== [3/5] 애플리케이션 배포 ==="
mkdir -p /opt/plc-simulator
cd /opt/plc-simulator

# requirements.txt 생성
cat > requirements.txt << 'REQEOF'
flask==3.0.2
gunicorn==21.2.0
numpy==1.26.4
REQEOF

# 가상환경 생성 및 패키지 설치
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# plc_simulator.py 배포 (위 소스코드를 이 경로에 배치)
# cp /path/to/plc_simulator.py /opt/plc-simulator/plc_simulator.py

echo "=== [4/5] systemd 서비스 등록 ==="
cat > /etc/systemd/system/plc-simulator.service << 'SVCEOF'
[Unit]
Description=PLC Simulator - Virtual Sensor Data Generator
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/plc-simulator
Environment="PATH=/opt/plc-simulator/venv/bin:/usr/bin"
ExecStart=/opt/plc-simulator/venv/bin/gunicorn \
    --bind 0.0.0.0:5000 \
    --workers 2 \
    --threads 4 \
    --timeout 120 \
    --access-logfile /var/log/plc-simulator/access.log \
    --error-logfile /var/log/plc-simulator/error.log \
    "plc_simulator:app"
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SVCEOF

mkdir -p /var/log/plc-simulator

echo "=== [5/5] 방화벽 및 서비스 시작 ==="
ufw allow 5000/tcp
ufw allow 22/tcp
ufw --force enable

systemctl daemon-reload
systemctl enable --now plc-simulator

echo "=== 설치 완료 ==="
echo "PLC API: http://192.168.201.11:5000"
echo "상태 확인: curl http://192.168.201.11:5000/api/health"
```

### Gunicorn 시작 시 백그라운드 스레드 초기화

Flask 애플리케이션을 Gunicorn으로 실행할 때 센서 업데이트 스레드가 자동 시작되도록 다음 코드를 `plc_simulator.py` 하단에 포함한다:

```python
# Gunicorn 호환: 워커 시작 시 백그라운드 스레드 자동 실행
_thread_started = False

def start_background_thread():
    global _thread_started
    if not _thread_started:
        update_thread = threading.Thread(target=sensor_update_loop, daemon=True)
        update_thread.start()
        _thread_started = True

# 앱 로딩 시 스레드 시작
start_background_thread()
```

---

## 7. OPNSense-5 방화벽 규칙 (PLC 시뮬레이터 관련)

| 순서 | 방향 | 출발지 | 목적지 | 프로토콜/포트 | 동작 | 설명 |
|------|------|--------|--------|---------------|------|------|
| 2 | IN | 192.168.201.0/24 | 192.168.201.0/24 | ANY | ALLOW | OT 내부 통신 허용 |
| 3 | OUT | 192.168.201.0/24 | 192.168.200.0/24 | ANY | BLOCK | OT→DMZ 이그레스 차단 |
| 4 | OUT | 192.168.201.0/24 | 192.168.100.0/24 | ANY | BLOCK | OT→INT 완전 차단 |
| 5 | OUT | 192.168.201.0/24 | 0.0.0.0/0 | ANY | BLOCK | OT 외부 통신 전면 차단 |
| 6 | IN | ANY | 192.168.201.0/24 | ANY | BLOCK | 기타 인바운드 전면 차단 |

**통신 흐름 (PLC 시뮬레이터 관련):**

| 출발지 | 목적지 | 포트 | 프로토콜 | 용도 |
|--------|--------|------|----------|------|
| SCADA (.10) Node-RED | PLC (.11) | TCP 5000 | HTTP GET | 센서 데이터 폴링 (5초) |
| PLC (.11) | SCADA (.10) | TCP 5000 응답 | HTTP Response | 센서 값 응답 |

---

## 8. 블루팀 탐지 포인트

### 8-1. Gunicorn 액세스 로그 모니터링

**로그 경로:** `/var/log/plc-simulator/access.log`

| 탐지 항목 | 로그 패턴 | 심각도 | 설명 |
|-----------|-----------|--------|------|
| 설정 조회 | `GET /api/config` | 중간 | 내부 설정 열람 (정찰) |
| 범위 변경 | `POST /api/set_range` | 높음 | 센서 출력 범위 조작 |
| 값 주입 | `POST /api/inject` | 높음 | 센서 값 강제 주입 |
| 비정상 IP | SCADA(.10) 외에서 접근 | 높음 | 허용되지 않은 호스트에서 접근 |

```bash
#!/bin/bash
# /opt/scripts/plc_api_monitor.sh
# PLC API 접근 모니터링

LOG_FILE="/var/log/plc-simulator/access.log"
ALERT_LOG="/var/log/ot-security/plc_api_alerts.log"

tail -F "$LOG_FILE" | while read line; do

    # 설정 조회 (정찰 행위)
    if echo "$line" | grep -q "GET /api/config"; then
        echo "[$(date -Iseconds)] RECON: PLC 설정 조회 감지 - $line" >> "$ALERT_LOG"
    fi

    # 범위 변경 시도
    if echo "$line" | grep -q "POST /api/set_range"; then
        echo "[$(date -Iseconds)] CRITICAL: PLC 센서 범위 변경 시도 - $line" >> "$ALERT_LOG"
    fi

    # 값 주입 시도
    if echo "$line" | grep -q "POST /api/inject"; then
        echo "[$(date -Iseconds)] CRITICAL: PLC 값 주입 시도 - $line" >> "$ALERT_LOG"
    fi

    # 비정상 IP 접근 (SCADA 서버 외)
    SRC_IP=$(echo "$line" | awk '{print $1}')
    if [ "$SRC_IP" != "192.168.201.10" ] && [ "$SRC_IP" != "127.0.0.1" ]; then
        echo "[$(date -Iseconds)] ALERT: 비정상 IP에서 PLC API 접근 ($SRC_IP) - $line" >> "$ALERT_LOG"
    fi

done
```

### 8-2. 탐지 시나리오 매핑 (PLC 관련)

```
[STEP 3-3] PLC 공격
+-----------------------+     +-----------------------------------+
| 공격 행위             | --> | 탐지 포인트                       |
+-----------------------+     +-----------------------------------+
| /api/config 정찰      | --> | access.log: GET /api/config       |
| /api/set_range 범위변경| --> | access.log: POST /api/set_range  |
| /api/inject 값 주입   | --> | access.log: POST /api/inject      |
| 비인가 IP 접근        | --> | access.log: src IP != .10         |
|                       | --> | 태그 이상: 값 고정 / 패턴 변화   |
+-----------------------+     +-----------------------------------+
```

### 8-3. 블루팀 대응 체크리스트 (PLC 관련)

| 순서 | 탐지 항목 | 확인 방법 | 대응 조치 |
|------|-----------|-----------|-----------|
| 1 | PLC API 무단 접근 | Gunicorn 액세스 로그 | 방화벽에서 비인가 IP 차단 |
| 2 | 센서 범위 조작 | /api/config 주기적 확인 | 원래 범위로 복원 (base_min/max 참조) |
| 3 | 값 주입 감지 | 값 고정 탐지 / injection_active 확인 | PLC 서비스 재시작, 주입 해제 |

---

## 부록: 환경 변수 요약

```bash
# PLC 시뮬레이터 관련
PLC_API=http://192.168.201.11:5000

# 센서 태그 ID (SCADA-LTS 측)
TAG_TEMPERATURE=DP_TEMP_01
TAG_PRESSURE=DP_PRES_01
TAG_FLOW_RATE=DP_FLOW_01
TAG_POWER=DP_POWR_01
```

---

*문서 끝*
