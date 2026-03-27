from django.urls import path
from . import views

urlpatterns = [
    path('', views.notice_list_view, name='notice-list'),
    path('<int:pk>/', views.notice_detail_view, name='notice-detail'),
]
