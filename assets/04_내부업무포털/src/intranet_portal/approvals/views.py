from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Approval


@login_required
def approval_list_view(request):
    """결재 문서 목록 페이지."""
    approvals = Approval.objects.all()
    status_filter = request.GET.get('status')
    if status_filter:
        approvals = approvals.filter(status=status_filter)
    return render(request, 'approvals/list.html', {
        'approvals': approvals,
    })


@login_required
def approval_detail_view(request, pk):
    """결재 문서 상세 페이지."""
    approval = get_object_or_404(
        Approval.objects.prefetch_related('approval_lines__approver'), pk=pk
    )
    return render(request, 'approvals/detail.html', {
        'approval': approval,
    })
