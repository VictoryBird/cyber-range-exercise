from django.contrib import admin
from .models import UserProfile, Department


@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ['user', 'department', 'position', 'employee_number']
    search_fields = ['user__username', 'user__first_name', 'department']
    list_filter = ['department', 'position']


@admin.register(Department)
class DepartmentAdmin(admin.ModelAdmin):
    list_display = ['name', 'code', 'head']
    search_fields = ['name', 'code']
