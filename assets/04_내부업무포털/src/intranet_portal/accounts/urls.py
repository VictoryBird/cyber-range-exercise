from django.urls import path
from . import views

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('profile/', views.profile_view, name='my-profile'),
    path('profile/<int:user_id>/', views.profile_detail_view, name='profile-detail'),
]
