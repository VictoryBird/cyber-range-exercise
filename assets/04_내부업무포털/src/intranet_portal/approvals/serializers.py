from rest_framework import serializers
from .models import Approval, ApprovalLine


class ApprovalLineSerializer(serializers.ModelSerializer):
    """결재선 시리얼라이저."""
    approver = serializers.SerializerMethodField()

    class Meta:
        model = ApprovalLine
        fields = ['order', 'approver', 'status', 'comment', 'acted_at']

    def get_approver(self, obj):
        return {
            'id': obj.approver.id,
            'name': obj.approver.get_full_name() or obj.approver.username,
            'position': getattr(obj.approver, 'userprofile', None)
                        and obj.approver.userprofile.position or '',
        }


class ApprovalListSerializer(serializers.ModelSerializer):
    """결재 목록 시리얼라이저."""
    requester = serializers.SerializerMethodField()
    current_approver = serializers.SerializerMethodField()

    class Meta:
        model = Approval
        fields = ['id', 'title', 'type', 'status', 'requester',
                  'current_approver', 'created_at']

    def get_requester(self, obj):
        return obj.requester.get_full_name() or obj.requester.username

    def get_current_approver(self, obj):
        current = obj.approval_lines.filter(status='pending').first()
        if current:
            return current.approver.get_full_name() or current.approver.username
        return None


class ApprovalDetailSerializer(serializers.ModelSerializer):
    """결재 상세 시리얼라이저."""
    requester = serializers.SerializerMethodField()
    approval_line = ApprovalLineSerializer(source='approval_lines', many=True)

    class Meta:
        model = Approval
        fields = ['id', 'title', 'type', 'status', 'requester',
                  'content', 'amount', 'approval_line', 'created_at', 'updated_at']

    def get_requester(self, obj):
        profile = getattr(obj.requester, 'userprofile', None)
        return {
            'id': obj.requester.id,
            'name': obj.requester.get_full_name() or obj.requester.username,
            'department': profile.department if profile else '',
            'position': profile.position if profile else '',
        }
