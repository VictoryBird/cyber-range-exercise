from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.WorkRequestListAPIView.as_view(), name='api-work-request-list'),
    path('<int:pk>/', api_views.WorkRequestDetailAPIView.as_view(), name='api-work-request-detail'),
]
