from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.db import connection


class SearchAPIView(APIView):
    """
    통합 검색 API.
    [취약점] VULN-SQLi: keyword 파라미터를 raw SQL에 직접 삽입 (파라미터 바인딩 미사용)
    안전한 구현: cursor.execute("... WHERE title LIKE %s", [f'%{keyword}%'])
               또는 Django ORM의 Q 객체와 __icontains 사용
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        keyword = request.query_params.get('keyword', '')
        search_type = request.query_params.get('type', 'all')

        if not keyword:
            return Response({"error": "검색어를 입력해 주세요."}, status=400)

        results = []

        with connection.cursor() as cursor:
            # ============================================
            # [취약점] VULN-SQLi: f-string으로 SQL 직접 조립
            # 안전한 방법: cursor.execute("... WHERE title LIKE %s", [f'%{keyword}%'])
            # ============================================

            if search_type in ('all', 'notice'):
                # 공지사항 검색 (취약한 raw SQL)
                sql = f"""
                    SELECT id, title, content, created_at, 'notice' as type
                    FROM notices_notice
                    WHERE title LIKE '%{keyword}%'
                       OR content LIKE '%{keyword}%'
                    ORDER BY created_at DESC
                    LIMIT 20
                """
                try:
                    cursor.execute(sql)
                    columns = [col[0] for col in cursor.description]
                    for row in cursor.fetchall():
                        results.append(dict(zip(columns, row)))
                except Exception:
                    pass  # 쿼리 오류 시 무시 (SQLi 시도 시 일부 실패 가능)

            if search_type in ('all', 'approval'):
                # 결재 문서 검색 (취약한 raw SQL)
                sql = f"""
                    SELECT id, title, status, created_at, 'approval' as type
                    FROM approvals_approval
                    WHERE title LIKE '%{keyword}%'
                    ORDER BY created_at DESC
                    LIMIT 20
                """
                try:
                    cursor.execute(sql)
                    columns = [col[0] for col in cursor.description]
                    for row in cursor.fetchall():
                        results.append(dict(zip(columns, row)))
                except Exception:
                    pass

            if search_type in ('all', 'user'):
                # 사용자 검색 (취약한 raw SQL — 비밀번호 해시 포함 테이블)
                sql = f"""
                    SELECT u.id, u.username, u.first_name, u.email,
                           p.department, p.position
                    FROM auth_user u
                    LEFT JOIN accounts_userprofile p ON u.id = p.user_id
                    WHERE u.first_name LIKE '%{keyword}%'
                       OR u.username LIKE '%{keyword}%'
                       OR p.department LIKE '%{keyword}%'
                    ORDER BY u.first_name
                    LIMIT 20
                """
                try:
                    cursor.execute(sql)
                    columns = [col[0] for col in cursor.description]
                    for row in cursor.fetchall():
                        results.append(dict(zip(columns, row)))
                except Exception:
                    pass

        return Response({
            "keyword": keyword,
            "type": search_type,
            "total": len(results),
            "results": results
        })
