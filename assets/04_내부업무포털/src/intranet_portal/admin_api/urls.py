from django.urls import path
from . import views

urlpatterns = [
    path('export-users', views.ExportUsersView.as_view(), name='admin-export-users'),
    path('create-user', views.CreateUserView.as_view(), name='admin-create-user'),
    path('system-info', views.SystemInfoView.as_view(), name='admin-system-info'),
]
