<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    /**
     * admin.jsp — 관리자 패널 (지도 객체 CRUD)
     *
     * [취약점] VULN-C13-03: 인증 부재 (CWE-306)
     * 관리자 기능에 대한 인증/세션 확인 없음
     * 누구나 admin.jsp에 접근하여 지도 객체를 추가/삭제 가능
     * [올바른 구현] 세션 기반 인증 + RBAC(역할 기반 접근 제어) 적용
     *   if (session.getAttribute("role") == null || !"admin".equals(session.getAttribute("role"))) {
     *       response.sendRedirect("login.jsp");
     *       return;
     *   }
     */

    String dbUrl = "jdbc:postgresql://localhost:5432/cop_db";
    String dbUser = "cop_user";
    String dbPass = "C0p!Map#2024";

    String action = request.getParameter("action");
    String message = "";

    Connection conn = null;
    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        if ("delete".equals(action)) {
            String delId = request.getParameter("id");
            if (delId != null) {
                // ★ SQL Injection (문자열 연결)
                Statement stmt = conn.createStatement();
                stmt.executeUpdate("DELETE FROM map_objects WHERE id = " + delId);
                stmt.close();
                message = "ID " + delId + " 삭제 완료";
            }
        }

        if ("add".equals(action) && "POST".equalsIgnoreCase(request.getMethod())) {
            String objType = request.getParameter("obj_type");
            String subType = request.getParameter("sub_type");
            String affiliation = request.getParameter("affiliation");
            String label = request.getParameter("label");  // ★ Stored XSS
            String lat = request.getParameter("lat");
            String lng = request.getParameter("lng");
            String color = request.getParameter("color");
            String icon = request.getParameter("icon");

            // ★ SQL Injection (문자열 연결)
            String sql = "INSERT INTO map_objects (obj_type, sub_type, affiliation, label, " +
                "position_lat, position_lng, color, icon, status) VALUES ('" +
                objType + "', '" + subType + "', '" + affiliation + "', '" + label + "', " +
                lat + ", " + lng + ", '" + color + "', '" + icon + "', 'active')";

            Statement stmt = conn.createStatement();
            stmt.executeUpdate(sql);
            stmt.close();
            message = "새 객체 추가 완료: " + label;
        }
    } catch (Exception e) {
        message = "오류: " + e.getMessage();
    }
%>
<!DOCTYPE html>
<html lang="ko">
<head>
    <meta charset="UTF-8">
    <title>COP 관리자 패널</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css">
    <style>
        body { background: #1a1a2e; color: #e0e0e0; font-family: 'Malgun Gothic', sans-serif; }
        .container { max-width: 1200px; margin-top: 20px; }
        h1 { color: #00d4ff; font-size: 22px; }
        .table { color: #e0e0e0; }
        .table th { background: #0f3460; }
        .table td { border-color: #0f3460; }
        .btn-danger { background: #cc0000; border: none; }
        .card { background: #16213e; border: 1px solid #0f3460; }
        .card-header { background: #0f3460; }
        .form-control, .form-select { background: #0a0a1a; color: #e0e0e0; border: 1px solid #0f3460; }
        .alert-success { background: #004400; border-color: #006600; color: #88ff88; }
        .alert-danger { background: #440000; border-color: #660000; color: #ff8888; }
    </style>
</head>
<body>

<div class="container">
    <h1>COP 관리자 패널 <small style="font-size:12px;color:#888;">(인증 없음 - 개발 모드)</small></h1>
    <a href="map.jsp" class="btn btn-sm btn-outline-info mb-3">상황도로 돌아가기</a>

    <% if (!message.isEmpty()) { %>
    <div class="alert alert-success"><%= message %></div>
    <% } %>

    <!-- 신규 추가 폼 -->
    <div class="card mb-3">
        <div class="card-header">지도 객체 추가</div>
        <div class="card-body">
            <form method="POST" action="admin.jsp?action=add">
                <div class="row g-2">
                    <div class="col-md-2">
                        <select name="obj_type" class="form-select">
                            <option value="unit">부대</option>
                            <option value="line">라인</option>
                            <option value="area">구역</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <select name="sub_type" class="form-select">
                            <option value="infantry">보병</option>
                            <option value="armor">기갑</option>
                            <option value="artillery">포병</option>
                            <option value="special">특수전</option>
                            <option value="air_defense">방공</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <select name="affiliation" class="form-select">
                            <option value="friendly">아군</option>
                            <option value="enemy">적군</option>
                            <option value="neutral">중립</option>
                        </select>
                    </div>
                    <div class="col-md-3">
                        <input type="text" name="label" class="form-control" placeholder="부대명" required>
                    </div>
                    <div class="col-md-1">
                        <input type="text" name="lat" class="form-control" placeholder="위도" required>
                    </div>
                    <div class="col-md-1">
                        <input type="text" name="lng" class="form-control" placeholder="경도" required>
                    </div>
                    <div class="col-md-1">
                        <input type="text" name="color" class="form-control" placeholder="#CC0000" value="#CC0000">
                        <input type="hidden" name="icon" value="circle">
                    </div>
                </div>
                <button type="submit" class="btn btn-primary btn-sm mt-2">추가</button>
            </form>
        </div>
    </div>

    <!-- 객체 목록 -->
    <div class="card">
        <div class="card-header">현재 지도 객체 (<span id="count">0</span>개)</div>
        <div class="card-body" style="max-height:500px;overflow-y:auto;">
            <table class="table table-sm table-dark table-striped">
                <thead>
                    <tr>
                        <th>ID</th><th>유형</th><th>소속</th><th>명칭</th>
                        <th>위도</th><th>경도</th><th>상태</th><th>작업</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    try {
                        Statement listStmt = conn.createStatement();
                        ResultSet listRs = listStmt.executeQuery(
                            "SELECT id, obj_type, sub_type, affiliation, label, position_lat, position_lng, status FROM map_objects ORDER BY id"
                        );
                        int count = 0;
                        while (listRs.next()) {
                            count++;
                %>
                    <tr>
                        <td><%= listRs.getInt("id") %></td>
                        <td><%= listRs.getString("obj_type") %> / <%= listRs.getString("sub_type") %></td>
                        <td><%= listRs.getString("affiliation") %></td>
                        <td><%= listRs.getString("label") %></td>
                        <td><%= listRs.getDouble("position_lat") %></td>
                        <td><%= listRs.getDouble("position_lng") %></td>
                        <td><%= listRs.getString("status") %></td>
                        <td>
                            <a href="admin.jsp?action=delete&id=<%= listRs.getInt("id") %>"
                               class="btn btn-danger btn-sm"
                               onclick="return confirm('삭제하시겠습니까?')">삭제</a>
                        </td>
                    </tr>
                <%
                        }
                        listRs.close();
                        listStmt.close();
                %>
                <script>document.getElementById('count').textContent = '<%= count %>';</script>
                <%
                    } catch (Exception e) {
                        out.print("<tr><td colspan='8'>오류: " + e.getMessage() + "</td></tr>");
                    } finally {
                        if (conn != null) try { conn.close(); } catch (SQLException e) {}
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</div>

</body>
</html>
