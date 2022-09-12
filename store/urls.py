from django.urls import path
from rest_framework.routers import SimpleRouter, DefaultRouter
from . import views


router = SimpleRouter()
router.register('products', views.ProductViewSet)
router.register('collections', views.CollectionViewSet)

urlpatterns = router.urls

# urlpatterns = [
#     path('products/', views.ProductList.as_view( )),
#     path('products/<int:pk>/', views.ProductDetail.as_view()), #<int:id> makes sure only int are entered in the link for the api
#     path('collections/', views.collection_list),
#     path('collections/<int:pk>/', views.CollectionDetail.as_view(), name='collection_detail'), #<int:id> makes sure only int are entered in the link for the api
# ]
