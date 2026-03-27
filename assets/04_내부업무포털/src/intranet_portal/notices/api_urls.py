from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.NoticeListAPIView.as_view(), name='api-notice-list'),
    path('<int:pk>/', api_views.NoticeDetailAPIView.as_view(), name='api-notice-detail'),
]
