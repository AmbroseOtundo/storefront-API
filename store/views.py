from rest_framework.filters import SearchFilter, OrderingFilter
from rest_framework.decorators import api_view
from rest_framework.mixins import CreateModelMixin, RetrieveModelMixin, DestroyModelMixin, UpdateModelMixin
from rest_framework.viewsets import ViewSet, ModelViewSet, GenericViewSet
from rest_framework.permissions import IsAuthenticated, AllowAny, IsAdminUser
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
from store.filters import ProductFilter
from store.pagination import DefaultPagination
from store.permissions import IsAdminOrReadOnly, ViewCustomerHistoryPermmission
from  .models import Cart, CartItem, Collection, Customer, Order, OrderItem, Product, Review
from django.db.models.aggregates import Count
from .serializers import AddCartItemSerializer, CartItemSerializer, CartSerializer, CreateOrderSerializer, CustomerSerializer, OrderSerializer, ProductSerializer, CollectionSerializer, ReviewSerializer, UpdateCartItemSerializer
from store import serializers


class ProductViewSet(ModelViewSet):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = ProductFilter
    permission_classes = [IsAdminOrReadOnly]
    search_fields = ['title', 'description']
    ordering_fields = ['unit_price', 'last_update']
    pagination_class = DefaultPagination

    def get_serializer_context(self):
        return {'request':self.request}
    
    def destroy(self, request, *args, **kwargs):
        if OrderItem.objects.filter(product_id=kwargs['pk']).count() > 0:
            return Response({'error':'Product cannot be deleted because it is associated with another product'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
        return super().destroy(request, *args, **kwargs)    

@api_view(['GET','POST'])
def collection_list(request):
    if request.method == 'GET':
        # this prevents lazy loading. ref in serializer collection object
        queryset = Collection.objects.annotate(products_count=Count('products')).all()
        serializer = CollectionSerializer(queryset, many=True)
        return Response(serializer.data)
    # This is the POST method. It is creating a new product.
    elif request.method == 'POST':
        serializer = CollectionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response('ok')
   
class CollectionViewSet(ModelViewSet):
    queryset = Collection.objects.annotate(products_count = Count('products'))
    serializer_class = CollectionSerializer
    permission_classes = [IsAdminOrReadOnly]

    def destroy(self, request, *args, **kwargs):
        if Collection.objects.filter(collection_id=kwargs['pk']).count() > 0:
            return Response({'error':'collection cannot be deleted because it is associated with another product'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
        return super().destroy(request, *args, **kwargs)   



class ReviewViewSet(ModelViewSet):
    serializer_class = ReviewSerializer

    def get_queryset(self):
        return Review.objects.filter(product_id=self.kwargs['product_pk'])

    def get_serializer_context(self):
        return {'product_id': self.kwargs['product_pk']}

class ReviewViewSet(ModelViewSet):
    serializer_class = ReviewSerializer
    def get_queryset(self):
        return Review.objects.filter(product_id=self.kwargs['product_pk'])

        # """
        # It returns a dictionary with the key 'product_id' and the value of the product_pk argument
        # """
    def get_serializer_context(self):
        return {'product_id': self.kwargs['product_pk']}

# we will not use the ModelViewSet, we will create a custom ViewSet
class CartViewSet(
                CreateModelMixin, 
                GenericViewSet,
                DestroyModelMixin, 
                RetrieveModelMixin):
    queryset = Cart.objects.prefetch_related('items__product').all()
    serializer_class = CartSerializer

class CartItemViewSet(ModelViewSet):
    # prevent the use of PUT
    http_method_names = ['get', 'post', 'patch', 'delete']
    
    def get_serializer_class(self):
        if self.request.method == 'POST':
            return AddCartItemSerializer
        elif self.request.method == 'PATCH':
            return UpdateCartItemSerializer
        return CartItemSerializer

    def get_serializer_context(self):
        return {'cart_id': self.kwargs['cart_pk']}
    def get_queryset(self):
        return CartItem.objects.filter(cart_id=self.kwargs['cart_pk']).select_related('product')

# Profile API
class CustomerViewSet(ModelViewSet):
    queryset = Customer.objects.all()
    serializer_class = CustomerSerializer
    # settting up permissions
    permission_classes = [IsAdminUser]

    @action(detail=True, permission_classes=ViewCustomerHistoryPermmission)
    def history(self, request, pk):
        return Response('ok')

    def get_permissions(self):
        if self.request.method == 'GET':
            return [AllowAny()]
        return [IsAuthenticated()]

    @action(detail=False, methods=['GET', 'PUT'], permission_classes=[IsAuthenticated])
    def me(self, request):
        (customer, creates) = Customer.objects.get_or_create(user_id=request.user.id)
        if request.method == 'GET':
            serializer = CustomerSerializer(customer)  
            return Response(serializer.data)
        elif request.method == 'PUT':
            serializer = CustomerSerializer(customer, data = request.data)
            serializer.is_valid(raise_exception=True)
            serializer.save()
            return Response(serializer.data)

class OrderViewSet(ModelViewSet):
    permission_classes = [IsAuthenticated]

    def get_serializer_class(self):
        if self.request.method == 'POST':
            return CreateOrderSerializer
        return OrderSerializer

    def get_serializer_context(self):
        return {'user_id': self.request.user.id}

    def get_queryset(self):
        user = self.request.user
        if user.is_staff:
            return Order.objects.all()

        (customer_id, created) =  Customer.objects.only('id').get_or_create(user_id=user.id)
        return Order.objects.filter(customer_id=customer_id)