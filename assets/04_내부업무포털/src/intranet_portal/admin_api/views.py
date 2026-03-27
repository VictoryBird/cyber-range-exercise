from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth.models import User
from django.conf import settings
from accounts.serializers import UserExportSerializer
from accounts.models import UserProfile
from datetime import datetime


class ExportUsersView(APIView):
    """
    전체 사용자 목록 내보내기.
    [취약점] VULN-AdminAPI: permission_classes 미설정 → 인증 불필요
    안전한 구현:
        from rest_framework.permissions import IsAuthenticated, IsAdminUser
        permission_classes = [IsAuthenticated, IsAdminUser]
    """
    # ============================================
    # [취약점] VULN-AdminAPI: 아래가 누락됨
    # permission_classes = [IsAuthenticated, IsAdminUser]
    # ============================================
    authentication_classes = []  # [취약점] 인증 완전 비활성화
    permission_classes = []      # [취약점] 권한 검사 완전 비활성화

    def get(self, request):
        users = User.objects.select_related('userprofile').all()
        serializer = UserExportSerializer(users, many=True)
        return Response({
            "total": users.count(),
            "exported_at": datetime.now().isoformat(),
            "users": serializer.data
        })


class CreateUserView(APIView):
    """
    새 사용자 생성.
    [취약점] VULN-AdminAPI: 인증 없이 관리자 계정 생성 가능
    안전한 구현:
        permission_classes = [IsAuthenticated, IsAdminUser]
    """
    authentication_classes = []  # [취약점] 인증 완전 비활성화
    permission_classes = []      # [취약점] 권한 검사 완전 비활성화

    def post(self, request):
        data = request.data
        username = data.get('username')
        password = data.get('password')
        name = data.get('name', '')
        email = data.get('email', '')
        department = data.get('department', '')
        position = data.get('position', '')
        is_staff = data.get('is_staff', False)
        is_superuser = data.get('is_superuser', False)

        if not username or not password:
            return Response(
                {"error": "username과 password는 필수입니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        if User.objects.filter(username=username).exists():
            return Response(
                {"error": "이미 존재하는 사용자명입니다."},
                status=status.HTTP_400_BAD_REQUEST
            )

        user = User.objects.create_user(
            username=username,
            password=password,
            first_name=name,
            email=email,
            is_staff=is_staff,
            is_superuser=is_superuser  # [취약점] 관리자 권한도 설정 가능
        )

        # UserProfile 생성
        UserProfile.objects.create(
            user=user,
            department=department,
            position=position,
            employee_number=f'MOIS-{datetime.now().year}-{user.id:04d}',
        )

        return Response(
            {"id": user.id, "username": user.username,
             "message": "사용자가 성공적으로 생성되었습니다."},
            status=status.HTTP_201_CREATED
        )


class SystemInfoView(APIView):
    """
    시스템 설정 정보 반환.
    [취약점] VULN-AdminAPI: DB, LDAP 크리덴셜 평문 노출 + 인증 없음
    안전한 구현:
        permission_classes = [IsAuthenticated, IsAdminUser]
        그리고 크리덴셜 정보는 절대 API로 노출하지 않아야 함
    """
    authentication_classes = []  # [취약점] 인증 완전 비활성화
    permission_classes = []      # [취약점] 권한 검사 완전 비활성화

    def get(self, request):
        return Response({
            "app_name": "MOIS Intranet Portal",
            "version": "2.1.0",
            "environment": settings.ENVIRONMENT,
            "database": {
                "engine": "postgresql",
                "host": settings.DATABASES['default']['HOST'],
                "port": settings.DATABASES['default']['PORT'],
                "name": settings.DATABASES['default']['NAME'],
                "user": settings.DATABASES['default']['USER'],
                "password": settings.DATABASES['default']['PASSWORD'],
            },
            "ldap": {
                "server": settings.AUTH_LDAP_SERVER_URI,
                "base_dn": settings.AUTH_LDAP_USER_SEARCH_BASE,
                "bind_dn": settings.AUTH_LDAP_BIND_DN,
                "bind_password": settings.AUTH_LDAP_BIND_PASSWORD,
            },
            "debug_mode": settings.DEBUG,
            "secret_key": settings.SECRET_KEY,
        })
