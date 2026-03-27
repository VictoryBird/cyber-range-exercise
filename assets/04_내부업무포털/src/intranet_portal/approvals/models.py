from django.db import models
from django.contrib.auth.models import User


class Approval(models.Model):
    """전자결재 문서 모델."""
    TYPE_CHOICES = [
        ('leave', '휴가'),
        ('expense', '경비'),
        ('general', '일반'),
        ('purchase', '구매'),
    ]
    STATUS_CHOICES = [
        ('draft', '작성중'),
        ('pending', '결재대기'),
        ('approved', '승인'),
        ('rejected', '반려'),
    ]

    title = models.CharField('제목', max_length=300)
    type = models.CharField('결재 유형', max_length=20, choices=TYPE_CHOICES, default='general')
    status = models.CharField('상태', max_length=20, choices=STATUS_CHOICES, default='draft')
    requester = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='requested_approvals', verbose_name='기안자'
    )
    content = models.TextField('내용')
    amount = models.DecimalField('금액', max_digits=12, decimal_places=0, null=True, blank=True)
    created_at = models.DateTimeField('작성일', auto_now_add=True)
    updated_at = models.DateTimeField('수정일', auto_now=True)

    class Meta:
        verbose_name = '결재 문서'
        verbose_name_plural = '결재 문서 목록'
        ordering = ['-created_at']

    def __str__(self):
        return f'[{self.get_type_display()}] {self.title}'


class ApprovalLine(models.Model):
    """결재선 모델."""
    STATUS_CHOICES = [
        ('waiting', '대기'),
        ('pending', '결재중'),
        ('approved', '승인'),
        ('rejected', '반려'),
    ]

    approval = models.ForeignKey(
        Approval, on_delete=models.CASCADE, related_name='approval_lines', verbose_name='결재 문서'
    )
    approver = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name='approval_lines', verbose_name='결재자'
    )
    order = models.PositiveIntegerField('결재 순서')
    status = models.CharField('상태', max_length=20, choices=STATUS_CHOICES, default='waiting')
    comment = models.TextField('의견', blank=True, default='')
    acted_at = models.DateTimeField('처리일', null=True, blank=True)

    class Meta:
        verbose_name = '결재선'
        verbose_name_plural = '결재선 목록'
        ordering = ['approval', 'order']
        unique_together = ['approval', 'order']

    def __str__(self):
        return f'{self.approval.title} - {self.order}순위: {self.approver}'
