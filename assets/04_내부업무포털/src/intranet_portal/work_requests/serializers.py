from rest_framework import serializers
from .models import WorkRequest


class WorkRequestListSerializer(serializers.ModelSerializer):
    """업무 요청 목록 시리얼라이저."""
    requester = serializers.SerializerMethodField()
    assignee = serializers.SerializerMethodField()

    class Meta:
        model = WorkRequest
        fields = ['id', 'title', 'requester', 'assignee', 'from_department',
                  'to_department', 'priority', 'status', 'due_date', 'created_at']

    def get_requester(self, obj):
        return obj.requester.get_full_name() or obj.requester.username

    def get_assignee(self, obj):
        if obj.assignee:
            return obj.assignee.get_full_name() or obj.assignee.username
        return None


class WorkRequestDetailSerializer(serializers.ModelSerializer):
    """업무 요청 상세 시리얼라이저."""
    requester = serializers.SerializerMethodField()
    assignee = serializers.SerializerMethodField()

    class Meta:
        model = WorkRequest
        fields = ['id', 'title', 'content', 'requester', 'assignee',
                  'from_department', 'to_department', 'priority', 'status',
                  'due_date', 'created_at', 'updated_at']

    def get_requester(self, obj):
        profile = getattr(obj.requester, 'userprofile', None)
        return {
            'id': obj.requester.id,
            'name': obj.requester.get_full_name() or obj.requester.username,
            'department': profile.department if profile else '',
        }

    def get_assignee(self, obj):
        if obj.assignee:
            profile = getattr(obj.assignee, 'userprofile', None)
            return {
                'id': obj.assignee.id,
                'name': obj.assignee.get_full_name() or obj.assignee.username,
                'department': profile.department if profile else '',
            }
        return None
