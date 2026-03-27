"""
내부 업무 포털 URL Configuration.
"""
from django.contrib import admin
from django.urls import path, include
from django.shortcuts import redirect
from . import views as main_views


def home_redirect(request):
    """홈페이지 → 대시보드 또는 로그인 리다이렉트."""
    if request.user.is_authenticated:
        return redirect('dashboard')
    return redirect('login')


urlpatterns = [
    # Django 관리자 (기본 내장)
    path('django-admin/', admin.site.urls),

    # 홈 및 대시보드
    path('', home_redirect, name='home'),
    path('dashboard/', main_views.dashboard_view, name='dashboard'),

    # 페이지 뷰 (템플릿 렌더링)
    path('accounts/', include('accounts.urls')),
    path('notices/', include('notices.urls')),
    path('approvals/', include('approvals.urls')),
    path('work-requests/', include('work_requests.urls')),
    path('search/', include('search.urls')),

    # REST API
    path('api/user/', include('accounts.api_urls')),
    path('api/notices/', include('notices.api_urls')),
    path('api/approvals/', include('approvals.api_urls')),
    path('api/work-requests/', include('work_requests.api_urls')),
    path('api/search', include('search.api_urls')),
    path('api/admin/', include('admin_api.urls')),  # [취약점] 인증 미적용 관리자 API
]
