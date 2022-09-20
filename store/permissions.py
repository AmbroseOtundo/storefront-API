from rest_framework.permissions import  BasePermission
from rest_framework import permissions

# If the request is safe (GET, HEAD, OPTIONS), then allow it. Otherwise, only allow it if the user is a staff member
class IsAdminOrReadOnly(BasePermission):
    def has_permission(self, request, view):
        if request.method in permissions.SAFE_METHODS:
            return
        return bool(request.user and request.user.is_staff)

class ViewCustomerHistoryPermmission(BasePermission):
    def has_permission(self, request, view):
        return request.user.has_perm('store.view_history')