from django.urls import path
from . import views

urlpatterns = [
    path('', views.approval_list_view, name='approval-list'),
    path('<int:pk>/', views.approval_detail_view, name='approval-detail'),
]
