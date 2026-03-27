from rest_framework import generics
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone
from .models import Approval, ApprovalLine
from .serializers import ApprovalListSerializer, ApprovalDetailSerializer


class ApprovalListAPIView(generics.ListAPIView):
    """결재 문서 목록 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = ApprovalListSerializer

    def get_queryset(self):
        queryset = Approval.objects.all()
        status_filter = self.request.query_params.get('status')
        type_filter = self.request.query_params.get('type')
        if status_filter:
            queryset = queryset.filter(status=status_filter)
        if type_filter:
            queryset = queryset.filter(type=type_filter)
        return queryset


class ApprovalDetailAPIView(generics.RetrieveAPIView):
    """결재 문서 상세 API."""
    permission_classes = [IsAuthenticated]
    serializer_class = ApprovalDetailSerializer
    queryset = Approval.objects.prefetch_related('approval_lines__approver')


class ApprovalApproveAPIView(APIView):
    """결재 승인 처리 API."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            approval = Approval.objects.get(pk=pk)
        except Approval.DoesNotExist:
            return Response({"error": "결재 문서를 찾을 수 없습니다."}, status=404)

        # 현재 결재자 확인
        current_line = approval.approval_lines.filter(
            status='pending', approver=request.user
        ).first()

        if not current_line:
            return Response({"error": "결재 권한이 없습니다."}, status=403)

        comment = request.data.get('comment', '')
        current_line.status = 'approved'
        current_line.comment = comment
        current_line.acted_at = timezone.now()
        current_line.save()

        # 다음 결재자 활성화
        next_line = approval.approval_lines.filter(
            order=current_line.order + 1
        ).first()

        if next_line:
            next_line.status = 'pending'
            next_line.save()
        else:
            # 최종 승인
            approval.status = 'approved'
            approval.save()

        return Response({"message": "승인 처리되었습니다."})


class ApprovalRejectAPIView(APIView):
    """결재 반려 처리 API."""
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        try:
            approval = Approval.objects.get(pk=pk)
        except Approval.DoesNotExist:
            return Response({"error": "결재 문서를 찾을 수 없습니다."}, status=404)

        current_line = approval.approval_lines.filter(
            status='pending', approver=request.user
        ).first()

        if not current_line:
            return Response({"error": "결재 권한이 없습니다."}, status=403)

        comment = request.data.get('comment', '')
        current_line.status = 'rejected'
        current_line.comment = comment
        current_line.acted_at = timezone.now()
        current_line.save()

        approval.status = 'rejected'
        approval.save()

        return Response({"message": "반려 처리되었습니다."})
