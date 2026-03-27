from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.contrib.auth.models import User
from .serializers import (
    UserProfileSerializer, DepartmentSerializer, DepartmentMemberSerializer
)
from .models import Department


class MyProfileView(APIView):
    """현재 로그인한 사용자의 프로필 조회 (정상 엔드포인트)."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        serializer = UserProfileSerializer(request.user)
        return Response(serializer.data)


class UserProfileByIdView(APIView):
    """
    사용자 프로필 조회 API.
    [취약점] VULN-IDOR: request.user.id와 url의 user_id를 비교하지 않음
    안전한 구현:
        if request.user.id != int(user_id):
            return Response({"error": "본인의 프로필만 조회할 수 있습니다."}, status=403)
    """
    permission_classes = [IsAuthenticated]  # 로그인만 확인, 본인 여부 미확인

    def get(self, request, user_id):
        # ============================================
        # [취약점] VULN-IDOR: 아래 검증이 누락됨
        # if request.user.id != int(user_id):
        #     return Response({"error": "권한 없음"}, status=403)
        # ============================================

        try:
            user = User.objects.select_related('userprofile').get(id=user_id)
        except User.DoesNotExist:
            return Response({"error": "사용자를 찾을 수 없습니다."}, status=404)

        serializer = UserProfileSerializer(user)
        return Response(serializer.data)


class DepartmentListView(APIView):
    """부서 목록 조회."""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        departments = Department.objects.all()
        serializer = DepartmentSerializer(departments, many=True)
        return Response({"departments": serializer.data})


class DepartmentMembersView(APIView):
    """부서원 목록 조회."""
    permission_classes = [IsAuthenticated]

    def get(self, request, dept_id):
        try:
            department = Department.objects.get(id=dept_id)
        except Department.DoesNotExist:
            return Response({"error": "부서를 찾을 수 없습니다."}, status=404)

        members = department.members.select_related('user').all()
        serializer = DepartmentMemberSerializer(members, many=True)
        return Response({
            "department": department.name,
            "members": serializer.data
        })
