from rest_framework import generics
from rest_framework.permissions import IsAuthenticated
from .models import WorkRequest
from .serializers import WorkRequestListSerializer, WorkRequestDetailSerializer


class WorkRequestListAPIView(generics.ListAPIView):
    """업무 요청 목록 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = WorkRequestListSerializer

    def get_queryset(self):
        queryset = WorkRequest.objects.all()
        status_filter = self.request.query_params.get('status')
        priority_filter = self.request.query_params.get('priority')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if priority_filter:
            queryset = queryset.filter(priority=priority_filter)
        return queryset


class WorkRequestDetailAPIView(generics.RetrieveAPIView):
    """업무 요청 상세 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = WorkRequestDetailSerializer
    queryset = WorkRequest.objects.all()
