from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Notice
from .serializers import NoticeListSerializer, NoticeDetailSerializer


class NoticeListAPIView(generics.ListAPIView):
    """공지사항 목록 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = NoticeListSerializer

    def get_queryset(self):
        queryset = Notice.objects.all()
        category = self.request.query_params.get('category')
        department = self.request.query_params.get('department')
        if category:
            queryset = queryset.filter(category=category)
        if department:
            queryset = queryset.filter(department=department)
        return queryset


class NoticeDetailAPIView(generics.RetrieveAPIView):
    """공지사항 상세 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = NoticeDetailSerializer
    queryset = Notice.objects.all()

    def retrieve(self, request, *args, **kwargs):
        instance = self.get_object()
        # 조회수 증가
        instance.view_count += 1
        instance.save(update_fields=['view_count'])
        serializer = self.get_serializer(instance)
        return Response(serializer.data)
