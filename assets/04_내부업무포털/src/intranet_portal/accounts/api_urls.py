from django.urls import path
from . import api_views

urlpatterns = [
    path('profile/', api_views.MyProfileView.as_view(), name='api-my-profile'),
    path('<int:user_id>/profile', api_views.UserProfileByIdView.as_view(), name='api-user-profile'),
    path('departments/', api_views.DepartmentListView.as_view(), name='api-departments'),
    path('departments/<int:dept_id>/members/', api_views.DepartmentMembersView.as_view(), name='api-dept-members'),
]
