<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.util.*, org.json.*" %>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>C4I 작전 상황도 (COP)</title>

    <!-- OpenLayers 7 -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/ol@7.5.2/ol.css">
    <script src="https://cdn.jsdelivr.net/npm/ol@7.5.2/dist/ol.js"></script>

    <!-- Bootstrap 5 -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

    <link rel="stylesheet" href="css/map.css">
</head>
<body>

<!-- 헤더 -->
<div id="header">
    <h1>C4I 작전 상황도 (COP)</h1>
    <div class="status">
        <span class="live">&#9679; 실시간</span>&nbsp;&nbsp;
        <span id="current-time"></span>&nbsp;&nbsp;
        <a href="admin.jsp" style="color:#aaa;font-size:12px;">[관리자]</a>
    </div>
</div>

<!-- 사이드 패널 -->
<div id="sidebar">
    <h3>부대 목록</h3>
    <div class="filter-section">
        <input type="text" id="search-input" placeholder="부대 검색..." onkeyup="filterUnits()">
    </div>
    <div class="filter-section">
        <label><input type="checkbox" class="filter-cb" value="friendly" checked> 아군</label><br>
        <label><input type="checkbox" class="filter-cb" value="enemy" checked> 적군</label><br>
        <label><input type="checkbox" class="filter-cb" value="neutral" checked> 중립</label>
    </div>
    <ul class="unit-list" id="unit-list">
        <!-- 동적으로 채워짐 -->
    </ul>
</div>

<!-- 지도 -->
<div id="map-container">
    <div id="map"></div>
</div>

<!-- 이벤트 타임라인 -->
<div id="timeline">
    <h3>이벤트 타임라인</h3>
    <div id="event-list">
        <!-- 동적으로 채워짐 -->
    </div>
</div>

<%
    // ============================================================
    // 서버 사이드: DB에서 map_objects 및 events 조회
    // ============================================================
    String dbUrl = "jdbc:postgresql://localhost:5432/cop_db";
    String dbUser = "cop_user";
    String dbPass = "C0p!Map#2024";

    StringBuilder mapObjectsJson = new StringBuilder("[");
    StringBuilder eventsJson = new StringBuilder("[");

    Connection conn = null;
    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        // map_objects 조회
        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(
            "SELECT id, obj_type, sub_type, affiliation, label, position_lat, position_lng, " +
            "positions_json, color, icon, metadata, status FROM map_objects WHERE status = 'active'"
        );
        boolean first = true;
        while (rs.next()) {
            if (!first) mapObjectsJson.append(",");
            first = false;
            mapObjectsJson.append("{");
            mapObjectsJson.append("\"id\":").append(rs.getInt("id")).append(",");
            mapObjectsJson.append("\"obj_type\":\"").append(rs.getString("obj_type")).append("\",");
            mapObjectsJson.append("\"sub_type\":\"").append(rs.getString("sub_type")).append("\",");
            mapObjectsJson.append("\"affiliation\":\"").append(rs.getString("affiliation")).append("\",");
            // [취약점] VULN-C13-02: label을 이스케이프 없이 출력 — Stored XSS 가능
            // [올바른 구현] StringEscapeUtils.escapeHtml4(label)로 HTML 이스케이프 처리
            mapObjectsJson.append("\"label\":\"").append(rs.getString("label")).append("\",");
            mapObjectsJson.append("\"lat\":").append(rs.getDouble("position_lat")).append(",");
            mapObjectsJson.append("\"lng\":").append(rs.getDouble("position_lng")).append(",");
            String posJson = rs.getString("positions_json");
            mapObjectsJson.append("\"positions\":").append(posJson != null ? posJson : "null").append(",");
            mapObjectsJson.append("\"color\":\"").append(rs.getString("color")).append("\",");
            mapObjectsJson.append("\"icon\":\"").append(rs.getString("icon")).append("\",");
            mapObjectsJson.append("\"status\":\"").append(rs.getString("status")).append("\"");
            mapObjectsJson.append("}");
        }
        rs.close();
        stmt.close();

        // events 조회 (최근 24시간)
        Statement evtStmt = conn.createStatement();
        ResultSet evtRs = evtStmt.executeQuery(
            "SELECT id, event_type, description, unit_name, location_lat, location_lng, " +
            "event_time, source, priority FROM events WHERE event_time > NOW() - INTERVAL '24 hours' " +
            "ORDER BY event_time DESC LIMIT 50"
        );
        first = true;
        while (evtRs.next()) {
            if (!first) eventsJson.append(",");
            first = false;
            eventsJson.append("{");
            eventsJson.append("\"id\":").append(evtRs.getInt("id")).append(",");
            eventsJson.append("\"type\":\"").append(evtRs.getString("event_type")).append("\",");
            eventsJson.append("\"description\":\"").append(evtRs.getString("description").replace("\"", "\\\"")).append("\",");
            eventsJson.append("\"unit\":\"").append(evtRs.getString("unit_name")).append("\",");
            eventsJson.append("\"lat\":").append(evtRs.getDouble("location_lat")).append(",");
            eventsJson.append("\"lng\":").append(evtRs.getDouble("location_lng")).append(",");
            eventsJson.append("\"time\":\"").append(evtRs.getTimestamp("event_time")).append("\",");
            eventsJson.append("\"source\":\"").append(evtRs.getString("source")).append("\",");
            eventsJson.append("\"priority\":\"").append(evtRs.getString("priority")).append("\"");
            eventsJson.append("}");
        }
        evtRs.close();
        evtStmt.close();

    } catch (Exception e) {
        e.printStackTrace();
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
    mapObjectsJson.append("]");
    eventsJson.append("]");
%>

<script>
// ============================================================
// 클라이언트 사이드: OpenLayers 지도 초기화
// ============================================================
const mapObjects = <%= mapObjectsJson.toString() %>;
const events = <%= eventsJson.toString() %>;

// 시간 표시
function updateTime() {
    const now = new Date();
    document.getElementById('current-time').textContent =
        now.toLocaleDateString('ko-KR') + ' ' + now.toLocaleTimeString('ko-KR');
}
setInterval(updateTime, 1000);
updateTime();

// OpenLayers 지도 초기화 — 한반도 중심
const map = new ol.Map({
    target: 'map',
    layers: [
        new ol.layer.Tile({
            source: new ol.source.OSM()
        })
    ],
    view: new ol.View({
        center: ol.proj.fromLonLat([127.0, 38.0]),
        zoom: 9,
        minZoom: 7,
        maxZoom: 15
    })
});

// 마커 스타일 정의
function getMarkerStyle(obj) {
    const colorMap = { 'friendly': '#0066CC', 'enemy': '#CC0000', 'neutral': '#009933' };
    const color = colorMap[obj.affiliation] || '#999999';

    return new ol.style.Style({
        image: new ol.style.Circle({
            radius: 8,
            fill: new ol.style.Fill({ color: color }),
            stroke: new ol.style.Stroke({ color: '#ffffff', width: 2 })
        }),
        text: new ol.style.Text({
            text: obj.label,
            offsetY: -18,
            font: '11px Malgun Gothic',
            fill: new ol.style.Fill({ color: color }),
            stroke: new ol.style.Stroke({ color: '#000000', width: 3 }),
            textAlign: 'center'
        })
    });
}

// 부대 마커 레이어
const unitFeatures = [];
const lineFeatures = [];
const areaFeatures = [];

mapObjects.forEach(function(obj) {
    if (obj.obj_type === 'unit' && obj.lat && obj.lng) {
        const feature = new ol.Feature({
            geometry: new ol.geom.Point(ol.proj.fromLonLat([obj.lng, obj.lat])),
            data: obj
        });
        feature.setStyle(getMarkerStyle(obj));
        unitFeatures.push(feature);
    } else if (obj.obj_type === 'line' && obj.positions) {
        const coords = obj.positions.map(p => ol.proj.fromLonLat([p.lng, p.lat]));
        const feature = new ol.Feature({
            geometry: new ol.geom.LineString(coords),
            data: obj
        });
        feature.setStyle(new ol.style.Style({
            stroke: new ol.style.Stroke({
                color: obj.color || '#00CC00',
                width: 3,
                lineDash: obj.icon === 'dashed_line' ? [10, 10] :
                          obj.icon === 'dotted_line' ? [3, 7] : undefined
            })
        }));
        lineFeatures.push(feature);
    } else if (obj.obj_type === 'area' && obj.positions) {
        const coords = obj.positions.map(p => ol.proj.fromLonLat([p.lng, p.lat]));
        coords.push(coords[0]);
        const feature = new ol.Feature({
            geometry: new ol.geom.Polygon([coords]),
            data: obj
        });
        const fillColor = obj.color || '#0066CC33';
        feature.setStyle(new ol.style.Style({
            fill: new ol.style.Fill({ color: fillColor }),
            stroke: new ol.style.Stroke({ color: fillColor.substring(0, 7), width: 2 })
        }));
        areaFeatures.push(feature);
    }
});

map.addLayer(new ol.layer.Vector({ source: new ol.source.Vector({ features: areaFeatures }), zIndex: 1 }));
map.addLayer(new ol.layer.Vector({ source: new ol.source.Vector({ features: lineFeatures }), zIndex: 2 }));
map.addLayer(new ol.layer.Vector({ source: new ol.source.Vector({ features: unitFeatures }), zIndex: 3 }));

// 사이드바 부대 목록 생성
const unitListEl = document.getElementById('unit-list');
mapObjects.filter(o => o.obj_type === 'unit').forEach(function(obj) {
    const li = document.createElement('li');
    li.setAttribute('data-affiliation', obj.affiliation);
    li.setAttribute('data-label', obj.label);
    const dotClass = 'dot dot-' + obj.affiliation;
    // [취약점] VULN-C13-02: label이 그대로 innerHTML에 삽입됨 — Stored XSS 가능
    // [올바른 구현] textContent를 사용하거나 DOMPurify로 sanitize
    li.innerHTML = '<span class="' + dotClass + '"></span>' + obj.label;
    li.onclick = function() {
        map.getView().animate({
            center: ol.proj.fromLonLat([obj.lng, obj.lat]),
            zoom: 12,
            duration: 500
        });
    };
    unitListEl.appendChild(li);
});

// 이벤트 타임라인 생성
const eventListEl = document.getElementById('event-list');
events.forEach(function(evt) {
    const row = document.createElement('div');
    row.className = 'event-row';
    const time = new Date(evt.time);
    const timeStr = time.getHours().toString().padStart(2,'0') + ':' + time.getMinutes().toString().padStart(2,'0');
    const typeMap = { 'friendly_move': ['아','badge-friendly'], 'enemy_advance': ['적','badge-enemy'],
                      'artillery_fire': ['포','badge-artillery'], 'air_support': ['공','badge-air'] };
    const badge = typeMap[evt.type] || ['?','badge-friendly'];
    row.innerHTML = '<span class="time">' + timeStr + '</span>' +
                    '<span class="badge-type ' + badge[1] + '">' + badge[0] + '</span>' +
                    '<span>' + evt.description + '</span>';
    eventListEl.appendChild(row);
});

// 30초 자동 새로고침
setInterval(function() { location.reload(); }, 30000);

// 부대 필터링
function filterUnits() {
    const search = document.getElementById('search-input').value.toLowerCase();
    const items = document.querySelectorAll('#unit-list li');
    items.forEach(function(li) {
        const label = li.getAttribute('data-label').toLowerCase();
        li.style.display = label.includes(search) ? '' : 'none';
    });
}

// 체크박스 필터
document.querySelectorAll('.filter-cb').forEach(function(cb) {
    cb.addEventListener('change', function() {
        const checked = Array.from(document.querySelectorAll('.filter-cb:checked')).map(c => c.value);
        document.querySelectorAll('#unit-list li').forEach(function(li) {
            const aff = li.getAttribute('data-affiliation');
            li.style.display = checked.includes(aff) ? '' : 'none';
        });
    });
});

// 팝업 오버레이
const popup = document.createElement('div');
popup.id = 'popup';
popup.style.cssText = 'background:#1a1a2e;color:#e0e0e0;padding:10px;border-radius:5px;border:1px solid #0f3460;font-size:12px;max-width:250px;display:none;position:absolute;z-index:2000;';
document.body.appendChild(popup);

const overlay = new ol.Overlay({
    element: popup,
    autoPan: true,
    autoPanAnimation: { duration: 250 }
});
map.addOverlay(overlay);

map.on('click', function(evt) {
    const feature = map.forEachFeatureAtPixel(evt.pixel, function(f) { return f; });
    if (feature && feature.get('data')) {
        const d = feature.get('data');
        popup.style.display = 'block';
        popup.innerHTML = '<b>' + d.label + '</b><br>' +
            '유형: ' + (d.sub_type || d.obj_type) + '<br>' +
            '소속: ' + d.affiliation + '<br>' +
            '좌표: ' + (d.lat ? d.lat.toFixed(4) + ', ' + d.lng.toFixed(4) : 'N/A');
        overlay.setPosition(evt.coordinate);
    } else {
        popup.style.display = 'none';
    }
});
</script>

</body>
</html>
