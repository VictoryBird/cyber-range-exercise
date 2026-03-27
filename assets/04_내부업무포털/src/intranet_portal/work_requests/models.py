from django.db import models
from django.contrib.auth.models import User


class WorkRequest(models.Model):
    """업무 요청 모델."""
    PRIORITY_CHOICES = [
        ('low', '낮음'),
        ('medium', '보통'),
        ('high', '높음'),
        ('urgent', '긴급'),
    ]
    STATUS_CHOICES = [
        ('open', '접수'),
        ('in_progress', '진행중'),
        ('completed', '완료'),
        ('cancelled', '취소'),
    ]

    title = models.CharField('제목', max_length=300)
    content = models.TextField('내용')
    requester = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='work_requests_made', verbose_name='요청자'
    )
    assignee = models.ForeignKey(
        User, on_delete=models.SET_NULL, null=True, blank=True,
        related_name='work_requests_assigned', verbose_name='담당자'
    )
    from_department = models.CharField('요청 부서', max_length=100, blank=True, default='')
    to_department = models.CharField('담당 부서', max_length=100, blank=True, default='')
    priority = models.CharField('우선순위', max_length=10, choices=PRIORITY_CHOICES, default='medium')
    status = models.CharField('상태', max_length=20, choices=STATUS_CHOICES, default='open')
    due_date = models.DateField('마감일', null=True, blank=True)
    created_at = models.DateTimeField('작성일', auto_now_add=True)
    updated_at = models.DateTimeField('수정일', auto_now=True)

    class Meta:
        verbose_name = '업무 요청'
        verbose_name_plural = '업무 요청 목록'
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.get_priority_display()}] {self.title}'
