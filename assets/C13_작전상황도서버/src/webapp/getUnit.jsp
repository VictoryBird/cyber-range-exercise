<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, org.json.*" %>
<%
    /**
     * getUnit.jsp — 부대 상세 정보 조회 API
     *
     * 사용법: getUnit.jsp?id=1
     *
     * [취약점] VULN-C13-01: SQL Injection (CWE-89)
     * 사용자 입력(id 파라미터)을 직접 SQL 쿼리에 문자열 연결 (PreparedStatement 미사용)
     * [올바른 구현] PreparedStatement를 사용하여 파라미터를 바인딩해야 함
     *   PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM map_objects WHERE id = ?");
     *   pstmt.setInt(1, Integer.parseInt(id));
     *
     * 공격 예시:
     *   getUnit.jsp?id=1' OR '1'='1
     *   getUnit.jsp?id=1' UNION SELECT null,null,null,null,label,null,null,null,null,null,null,null,null FROM map_objects--
     *   getUnit.jsp?id=1'; INSERT INTO map_objects (obj_type,sub_type,affiliation,label,position_lat,position_lng,color,icon,status) VALUES ('unit','armor','enemy','가짜 적 기갑사단',37.85,126.95,'#CC0000','armor','active');--
     */

    response.setContentType("application/json; charset=UTF-8");

    String id = request.getParameter("id");

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

        // [취약점] VULN-C13-01: SQL Injection — 문자열 연결 사용 (PreparedStatement 미사용)
        // [올바른 구현] PreparedStatement pstmt = conn.prepareStatement("SELECT * FROM map_objects WHERE id = ?");
        //              pstmt.setInt(1, Integer.parseInt(id));
        String sql = "SELECT * FROM map_objects WHERE id = '" + id + "'";

        Statement stmt = conn.createStatement();
        ResultSet rs = stmt.executeQuery(sql);

        JSONArray results = new JSONArray();
        ResultSetMetaData meta = rs.getMetaData();
        int cols = meta.getColumnCount();

        while (rs.next()) {
            JSONObject row = new JSONObject();
            for (int i = 1; i <= cols; i++) {
                String colName = meta.getColumnName(i);
                Object val = rs.getObject(i);
                row.put(colName, val != null ? val.toString() : JSONObject.NULL);
            }
            results.put(row);
        }

        if (results.length() == 0) {
            out.print("{\"error\": \"해당 ID의 객체를 찾을 수 없습니다\"}");
        } else if (results.length() == 1) {
            out.print(results.getJSONObject(0).toString());
        } else {
            out.print(results.toString());
        }

        rs.close();
        stmt.close();

    } catch (Exception e) {
        // ★ 오류 메시지에 SQL 에러 상세 노출 — 정보 유출
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        if (conn != null) try { conn.close(); } catch (SQLException e) {}
    }
%>
