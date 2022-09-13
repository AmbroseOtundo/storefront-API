from django.urls import path
from rest_framework_nested import routers
from . import views


# Creating a router for the products and collections.
router = routers.DefaultRouter()
router.register('products', views.ProductViewSet)
router.register('collections', views.CollectionViewSet)

# Creating a nested router.
products_router = routers.NestedDefaultRouter(router, 'products', lookup='product')
products_router.register('reviews', views.ReviewViewSet, basename='product-reviews')

urlpatterns = router.urls + products_router.urls

# urlpatterns = [
#     path('products/', views.ProductList.as_view( )),
#     path('products/<int:pk>/', views.ProductDetail.as_view()), #<int:id> makes sure only int are entered in the link for the api
#     path('collections/', views.collection_list),
#     path('collections/<int:pk>/', views.CollectionDetail.as_view(), name='collection_detail'), #<int:id> makes sure only int are entered in the link for the api
# ]
