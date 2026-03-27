from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.contrib.auth.models import User
from django.contrib import messages


def login_view(request):
    """로그인 페이지."""
    if request.user.is_authenticated:
        return redirect('dashboard')

    if request.method == 'POST':
        username = request.POST.get('username', '')
        password = request.POST.get('password', '')
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            next_url = request.GET.get('next', '/')
            return redirect(next_url)
        else:
            messages.error(request, '아이디 또는 비밀번호가 올바르지 않습니다.')

    return render(request, 'accounts/login.html')


def logout_view(request):
    """로그아웃."""
    logout(request)
    return redirect('login')


@login_required
def profile_view(request):
    """내 프로필 페이지."""
    return render(request, 'accounts/profile.html', {'profile_user': request.user})


@login_required
def profile_detail_view(request, user_id):
    """사용자 프로필 상세 페이지."""
    user = get_object_or_404(User.objects.select_related('userprofile'), id=user_id)
    return render(request, 'accounts/profile.html', {'profile_user': user})
