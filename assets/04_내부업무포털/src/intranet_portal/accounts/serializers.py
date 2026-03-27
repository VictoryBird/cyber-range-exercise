from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile, Department


class UserProfileSerializer(serializers.ModelSerializer):
    """
    사용자 프로필 시리얼라이저.
    [취약점] is_admin, is_staff, last_login 등 민감 필드 노출
    안전한 구현: is_superuser, is_staff, last_login 필드를 제외해야 함
    """
    department = serializers.CharField(source='userprofile.department', default='')
    position = serializers.CharField(source='userprofile.position', default='')
    phone = serializers.CharField(source='userprofile.phone', default='')
    employee_number = serializers.CharField(source='userprofile.employee_number', default='')
    joined_at = serializers.DateField(source='userprofile.joined_at', default=None)
    name = serializers.CharField(source='first_name')
    is_admin = serializers.BooleanField(source='is_superuser')

    class Meta:
        model = User
        fields = [
            'id', 'username', 'name', 'email',
            'department', 'position', 'phone', 'employee_number',
            'joined_at', 'is_admin', 'is_staff', 'last_login'
        ]


class UserExportSerializer(serializers.ModelSerializer):
    """사용자 내보내기용 시리얼라이저 (admin API)."""
    department = serializers.CharField(source='userprofile.department', default='')
    position = serializers.CharField(source='userprofile.position', default='')
    name = serializers.CharField(source='first_name')

    class Meta:
        model = User
        fields = [
            'id', 'username', 'name', 'email', 'department', 'position',
            'is_active', 'is_staff', 'is_superuser', 'date_joined', 'last_login'
        ]


class DepartmentSerializer(serializers.ModelSerializer):
    """부서 시리얼라이저."""
    head_name = serializers.SerializerMethodField()
    member_count = serializers.SerializerMethodField()

    class Meta:
        model = Department
        fields = ['id', 'name', 'code', 'head_name', 'member_count']

    def get_head_name(self, obj):
        if obj.head:
            return obj.head.get_full_name() or obj.head.username
        return None

    def get_member_count(self, obj):
        return obj.members.count()


class DepartmentMemberSerializer(serializers.ModelSerializer):
    """부서원 시리얼라이저."""
    name = serializers.CharField(source='user.first_name')
    email = serializers.EmailField(source='user.email')
    user_id = serializers.IntegerField(source='user.id')

    class Meta:
        model = UserProfile
        fields = ['user_id', 'name', 'position', 'email']
