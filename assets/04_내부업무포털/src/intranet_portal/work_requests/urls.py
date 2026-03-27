from django.urls import path
from . import views

urlpatterns = [
    path('', views.work_request_list_view, name='work-request-list'),
    path('<int:pk>/', views.work_request_detail_view, name='work-request-detail'),
]
