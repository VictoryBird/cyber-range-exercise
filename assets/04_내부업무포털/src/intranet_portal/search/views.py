from django.shortcuts import render
from django.contrib.auth.decorators import login_required


@login_required
def search_view(request):
    """통합 검색 페이지 (결과는 AJAX로 api_views.SearchAPIView에서 가져옴)."""
    keyword = request.GET.get('keyword', '')
    return render(request, 'search/results.html', {
        'keyword': keyword,
    })
