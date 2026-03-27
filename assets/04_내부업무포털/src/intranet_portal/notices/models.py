from django.db import models
from django.contrib.auth.models import User


class Notice(models.Model):
    """공지사항 모델."""
    CATEGORY_CHOICES = [
        ('일반', '일반'),
        ('보안', '보안'),
        ('인사', '인사'),
        ('IT', 'IT'),
        ('행사', '행사'),
    ]

    title = models.CharField('제목', max_length=300)
    content = models.TextField('내용')
    category = models.CharField('분류', max_length=20, choices=CATEGORY_CHOICES, default='일반')
    department = models.CharField('작성 부서', max_length=100, blank=True, default='')
    author = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, verbose_name='작성자')
    is_pinned = models.BooleanField('상단 고정', default=False)
    view_count = models.PositiveIntegerField('조회수', default=0)
    created_at = models.DateTimeField('작성일', auto_now_add=True)
    updated_at = models.DateTimeField('수정일', auto_now=True)

    class Meta:
        verbose_name = '공지사항'
        verbose_name_plural = '공지사항 목록'
        ordering = ['-is_pinned', '-created_at']

    def __str__(self):
        return self.title
