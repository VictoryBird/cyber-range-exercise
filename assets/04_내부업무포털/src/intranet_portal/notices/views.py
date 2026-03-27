from django.shortcuts import render, get_object_or_404
from django.contrib.auth.decorators import login_required
from .models import Notice


@login_required
def notice_list_view(request):
    """공지사항 목록 페이지."""
    notices = Notice.objects.all()
    category = request.GET.get('category')
    if category:
        notices = notices.filter(category=category)
    return render(request, 'notices/list.html', {
        'notices': notices,
        'categories': ['일반', '보안', '인사', 'IT', '행사'],
        'current_category': category,
    })


@login_required
def notice_detail_view(request, pk):
    """공지사항 상세 페이지."""
    notice = get_object_or_404(Notice, pk=pk)
    notice.view_count += 1
    notice.save(update_fields=['view_count'])
    return render(request, 'notices/detail.html', {'notice': notice})
