from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import WorkRequest


@login_required
def work_request_list_view(request):
    """업무 요청 목록 페이지."""
    requests = WorkRequest.objects.all()
    status_filter = request.GET.get('status')
    if status_filter:
        requests = requests.filter(status=status_filter)
    return render(request, 'work_requests/list.html', {
        'work_requests': requests,
    })


@login_required
def work_request_detail_view(request, pk):
    """업무 요청 상세 페이지."""
    work_request = get_object_or_404(WorkRequest, pk=pk)
    return render(request, 'work_requests/detail.html', {
        'work_request': work_request,
    })
