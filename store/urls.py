from django.urls import path
from . import views

urlpatterns = [
    path('products/', views.product_list),
    path('products/<int:id>/', views.product_detail), #<int:id> makes sure only int are entered in the link for the api
    path('collections/<int:pk>/', views.collection_detail, name='collection_detail'), #<int:id> makes sure only int are entered in the link for the api
]
