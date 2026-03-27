import logging
import json
from datetime import datetime


audit_logger = logging.getLogger('audit')


class AuditLogMiddleware:
    """
    감사 대상 경로에 대한 요청을 로그로 기록한다.
    블루팀이 비정상 접근(IDOR, SQLi, Admin API 무인증 접근)을 탐지하는 데 활용된다.
    """
    AUDIT_PATHS = [
        '/api/user/',
        '/api/admin/',
        '/api/approvals/',
        '/api/search',
    ]

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        response = self.get_response(request)

        for path in self.AUDIT_PATHS:
            if request.path.startswith(path):
                audit_logger.info(json.dumps({
                    "timestamp": datetime.now().isoformat(),
                    "user": str(request.user),
                    "method": request.method,
                    "path": request.get_full_path(),
                    "status": response.status_code,
                    "ip": request.META.get('REMOTE_ADDR'),
                    "user_agent": request.META.get('HTTP_USER_AGENT', ''),
                }, ensure_ascii=False))
                break

        return response
