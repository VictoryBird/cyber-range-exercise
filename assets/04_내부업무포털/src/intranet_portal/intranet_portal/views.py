from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from notices.models import Notice
from approvals.models import Approval
from work_requests.models import WorkRequest


@login_required
def dashboard_view(request):
    """대시보드 (홈) 페이지."""
    context = {
        'notice_count': Notice.objects.count(),
        'pending_approvals': Approval.objects.filter(status='pending').count(),
        'open_requests': WorkRequest.objects.filter(status='open').count(),
        'total_users': User.objects.filter(is_active=True).count(),
        'recent_notices': Notice.objects.all()[:5],
        'pending_approval_list': Approval.objects.filter(status='pending')[:5],
    }
    return render(request, 'dashboard/index.html', context)
