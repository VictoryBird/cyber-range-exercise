from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.ApprovalListAPIView.as_view(), name='api-approval-list'),
    path('<int:pk>/', api_views.ApprovalDetailAPIView.as_view(), name='api-approval-detail'),
    path('<int:pk>/approve/', api_views.ApprovalApproveAPIView.as_view(), name='api-approval-approve'),
    path('<int:pk>/reject/', api_views.ApprovalRejectAPIView.as_view(), name='api-approval-reject'),
]
