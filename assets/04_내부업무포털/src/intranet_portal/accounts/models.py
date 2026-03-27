from django.db import models
from django.contrib.auth.models import User


class Department(models.Model):
    """부서 모델."""
    name = models.CharField('부서명', max_length=100, unique=True)
    code = models.CharField('부서 코드', max_length=20, unique=True)
    head = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='headed_departments', verbose_name='부서장'
    )
    parent = models.ForeignKey(
        'self', on_delete=models.SET_NULL, null=True, blank=True,
        related_name='children', verbose_name='상위 부서'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name = '부서'
        verbose_name_plural = '부서 목록'
        ordering = ['name']

    def __str__(self):
        return self.name


class UserProfile(models.Model):
    """사용자 프로필 확장 모델 (Django User 모델과 1:1 연결)."""
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='userprofile')
    department = models.CharField('부서', max_length=100, blank=True, default='')
    department_ref = models.ForeignKey(
        Department, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='members', verbose_name='부서 참조'
    )
    position = models.CharField('직급', max_length=50, blank=True, default='')
    phone = models.CharField('전화번호', max_length=20, blank=True, default='')
    employee_number = models.CharField('사번', max_length=30, blank=True, default='')
    joined_at = models.DateField('입사일', null=True, blank=True)
    ad_username = models.CharField('AD 계정명', max_length=100, blank=True, default='')

    class Meta:
        verbose_name = '사용자 프로필'
        verbose_name_plural = '사용자 프로필 목록'

    def __str__(self):
        return f'{self.user.get_full_name()} ({self.department} {self.position})'
