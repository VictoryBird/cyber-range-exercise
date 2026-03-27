from rest_framework import serializers
from .models import Notice


class NoticeListSerializer(serializers.ModelSerializer):
    """공지사항 목록 시리얼라이저."""
    author = serializers.SerializerMethodField()

    class Meta:
        model = Notice
        fields = ['id', 'title', 'category', 'department', 'author',
                  'is_pinned', 'created_at', 'view_count']

    def get_author(self, obj):
        if obj.author:
            return obj.author.get_full_name() or obj.author.username
        return '알 수 없음'


class NoticeDetailSerializer(serializers.ModelSerializer):
    """공지사항 상세 시리얼라이저."""
    author = serializers.SerializerMethodField()

    class Meta:
        model = Notice
        fields = ['id', 'title', 'category', 'department', 'author',
                  'content', 'is_pinned', 'created_at', 'updated_at', 'view_count']

    def get_author(self, obj):
        if obj.author:
            return obj.author.get_full_name() or obj.author.username
        return '알 수 없음'
