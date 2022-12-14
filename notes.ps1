# 1. What are RESTful API
REST -- Representational State Transfer
  # what makes an API RESTFUL
   -- BENEFITS--
   ``` Fast
   ```Scaleble
   ```Reliable
   ```Easy to understand
   ```Easy to change --
        -- these are the rules that makes an API RESTFUL

    -- MAIN CONCEPTS
    ``` RESOURCES
    ```REPRESENTATIONS
    ```HTTP METHODS
  
2. RESOURCES
-- These are like -- products, orders in our application. They are acccesed by a URL.

3. REPRESENTATIONS
-- The data from a resource can be returned in like : HMTL, XML, JSON

4. HTTP METHODS
-- Endpoints are projected to clients -- 
GET= getting a collection
POST= create
PUT= updating
PATCH= Update part of a resource
DELETE

# adding views to the store app
-- first add the views by importing http response -- small letter response and not capital letter
-- second create the urls.py file and from  the . *(current dir) import views
-- go to the root folder for the project -- (storefront) add url link  --)path('store/', include('store.urls')),

#Serializer
--convert a model instance to a dictionary -- in 
  other words turns models or classes to JSON objects

  # make decimal value to be a decimal value -- add this in settings
REST_FRAMEWORK = {
    'COERCE_DECIMAL_TO_STRING':False
}
-- example response  -- 
                {
                    "id": 1,
                    "title": "Bread Ww Cluster",
                    "unit_price": 4.0
                }


  -- asking for an object that does not exist
first we from rest_framework import status
wrap the code in a try -- except function
--Example
       try:
        product = Product.objects.get(pk=id)
        serializer = ProductSerializer(product)
        return Response(serializer.data)
    except Product.DoesNotExist:
        return Response (status=status.HTTP_404_NOT_FOUND)

# we have a shortcut for exposing the errors
    from django.shortcuts import get_object_or_404
    
      @api_view()
      def product_detail(request, id):
          product = get_object_or_404(Product, pk=id)
          serializer = ProductSerializer(product)
          return Response(serializer.data)
        
# Returning all our products
@api_view()
def product_list(request):
    queryset = Product.objects.all()
    serializer = ProductSerializer(queryset, many=True)
    return Response(serializer.data)

#  Creatinng custom Serialiezer fields
class ProductSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField(max_length=255)
    # source helps django look for the source of the price 
    # becuause in the product class we do not have the price and instead we have unit_price
    price = serializers.DecimalField(max_digits=6, decimal_places=2, source = 'unit_price') 
    # custome serializer
    price_with_tax = serializers.SerializerMethodField(method_name='calculate_tax')
    # method to return price_with_tax
    def calculate_tax(self, product: Product):
        return product.unit_price * Decimal(1.1)
     
    to convert the decimal price, we import Decimal from decimal and wrap the the float with the class Decimal

# Serializing Relationships
 collection = serializers.PrimaryKeyRelatedField(
        queryset = Collection.objects.all()
    )

    The four ways to serialize an object
    --Primary
    --String
    --Nested
    --Hyperlink -- i love this

# Model serializers
Helps us reduce repetition
we use the meta class
  class ProductSerializer(serializers.ModelSerializer): #must include Model to the serializer
    class Meta:
        model = Product
        fields = ['id', 'title', 'unit_price', 'collection']


# Deserializing Objects
--@api_view(['GET', 'POST']) #we include the GET AND POST methods
def product_list(request):
    if request.method == 'GET':
        # this prevents lazy loading. ref in serializer collection object
        queryset = Product.objects.select_related('collection').all() 
        serializer = ProductSerializer(queryset, many=True, context={'request':request})
        return Response(serializer.data)
        # deserializing happens here.
    elif request.method == 'POST':
        serializer = ProductSerializer(data=request.data)
        # serializer.validated_data
        return Response('ok')

# Validating Data when deserializing
   if serializer.is_valid():
            serializer.validated_data
            return Response('ok')
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
 -- A more cleaner way to validate the data
   serializer.is_valid(raise_exception=True)
        serializer.validated_data
        return Response('ok')

# Saving data in the DB
 serializer.save()

#  ADVANCED API CONCEPTS
# Class Based Views
from rest_framework.views import APIView
-- this is the base class of all class based views

#  Mixins
is a class that encapsulates a code
-- first we import from rest_framework.mixins import ListModelMixin, CreateModelMixin
# Generic views
-- they combine two or more mixins
-- example : from rest_framework.generics import ListCreateAPIView


# Customizing our generic views
-- original code
            @api_view(['GET', 'PUT', 'DELETE'])
def collection_detail(request, pk):
    collection = get_object_or_404(
        Collection.objects.annotate(
            products_count=Count('products')), pk=pk)
    if request.method == 'GET':        
        serializer = CollectionSerializer(collection)
        return Response(serializer.data)
    elif request.method == 'PUT':
        serializer = CollectionSerializer(Collection, data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    elif request.method == 'DELETE':
        # This is checking if the product has any order items. If it does, it returns a 405 error.
        if collection.products.count() > 0:
            return Response({'error':'Collection cannot be deleted because it includes one or more products'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
        collection.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)


    # After customization
    class ProductList(ListCreateAPIView):
    queryset = Product.objects.select_related('collection').all() 
    serializer_class = ProductSerializer
    def get_serializer_context(self):
        return {'request':self.request}
    
    NOTE: If some code has some  logic e.g if else statements we leave them as they are.
    example: The delete handler has some logic
        class ProductDetail(RetrieveUpdateDestroyAPIView):
        queryset = Product.objects.all()
        serializer_class = ProductSerializer
        def delete(self, request, id):
            product = get_object_or_404(Product, pk=id)
            # This is checking if the product has any order items. If it does, it returns a 405 error.
            if product.orderitems.count() > 0:
                return Response({'error':'Product cannot be deleted because it is associated with another product'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
            product.delete()
            return Response(status=status.HTTP_204_NO_CONTENT)
# Viewsetsw

This is a set of related views.

from rest_framework.viewsets import ViewSet

class ProductViewSet(ModelViewSet):
    queryset = Product.objects.all() 
    serializer_class = ProductSerializer
     
    def get_serializer_context(self):
        return {'request':self.request}
    def delete(self, request, pk):
        product = get_object_or_404(Product, pk=pk)
        # This is checking if the product has any order items. If it does, it returns a 405 error.
        if product.orderitems.count() > 0:
            return Response({'error':'Product cannot be deleted because it is associated with another product'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
        product.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

# Routers
--We use this when we employ viewsets in the url.py file
-- from rest_framework.routers import SimpleRouter -- do this in the url file
router = SimpleRouter()
router.register('product', views.ProductViewSet)

# Reviews API

-- create a model class
-- create a migration
-- Apply the migration

-- building the API
--Create the serializer
-- create a view
-- register a route
 

 -- Nested Routers
  -- https://github.com/alanjds/drf-nested-routers
  pip install drf-nested-routers
# Creating a router for the products and collections.
router = routers.DefaultRouter()
router.register('products', views.ProductViewSet)
router.register('collections', views.CollectionViewSet)

# Creating a nested router.
products_router = routers.NestedDefaultRouter(router, 'products', lookup='product_pk')
products_router.register('reviews', views.ReviewViewSet, basename='product-reviews')

urlpatterns = router.urls + products_router.urls

# Filtering products

def get_queryset(self):
        queryset = Product.objects.all()
        collection_id = self.request.query_params.get('collection_id')
        if collection_id is not None:
            queryset = queryset.filter(collection_id=collection_id)
        return queryset

# Generic Filtering
--we use Django Filter
--pip install django-filter
-- we add it in the list of installed apps : django_filters
-- we import from django_filters.rest_framework import DjangoFilterBackend

        -- queryset = Product.objects.all()
    serializer_class = ProductSerializer
    filter_backends = [DjangoFilterBackend]
    filterset_fields = ['collection_id']

    # custom filter
    
    from .models import Product
from django_filters.rest_framework import FilterSet
-- for more info check the django filter documentation

class ProductFilter(FilterSet):
    class Meta:
        model = Product
        fields = {
            'collection_id': ['exact'],
            'unit_price':  ['gt', 'lt']
        }

# Searching
-- from rest_framework.filters import SearchFilter
--  search_fields = ['title', 'description']
    
        class ProductViewSet(ModelViewSet):
            queryset = Product.objects.all()
            serializer_class = ProductSerializer
            filter_backends = [DjangoFilterBackend, SearchFilter]
            filterset_class = ProductFilter
            search_fields = ['title', 'description']
# Sorting
from rest_framework.filters import SearchFilter, OrderingFilter

    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    ordering_fields = ['unit_price', 'last_update']

# Pagination

-- from rest_framework.pagination import PageNumberPagination
-- we go to the settings
--REST_FRAMEWORK = {
    'COERCE_DECIMAL_TO_STRING':False,
    'DEFAULT_PAGINATION_CLASS': 'rest_framework.pagination.PageNumberPagination',
      'PAGE_SIZE':10,
}

# OR
-- we can create a  new pagination file 
pagination.py

# Building A Shopping Cart API -- Designing and Implementing a Shopping Cart API (50m)
# Design phase
-- create a cart - POST /carts/  {} cart
- add items to a cart - POST /carts/:id/items {prodId, qty} item
- Update the items quantity - PATCH /cart/:id/items/:id {qty} {qty}
- Remove items from cart
- get a cart with its items -  GET /carts/:id {} cart
- delete a cart -  GET /carts/:id {}  {}
#  create a datA model by add a constrain of using UUID

# Creating the cart
create a Serializer
create a cview 
create a route
from rest_framework.mixins import CreateModelMixin
from rest_framework.viewsets import ViewSet, ModelViewSet, GenericViewSet

# Getting the cart

# adding a cart item

# Django Authentication System
#   -- Creating a User Model
        -- Extending the user model -- 
        -- As as best practice create the user model at the  start of your project.
        -- There is a big issue in creating it  mid way and the solution is we drop our database and recreate it again
# Creating user profiles
  user = models.OneToOneField(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)

#   groups and permissions
# creating custom user permissions

# Authentication
# Token Based AUTH -- 
    # -- Adding the authenticatio Endpoints
      -- DJOSER  library-- RESTful auth -- check the docs for installation
      -- we have two Authentication engines;
            -- Token Based Authentication -- use DB Table to store tokens
            -- JSON Web Token Authentication -- Does not DB
    # Using JWT Auth
    -- go to the docs and look at JSON Web Authentication
    -- pip install -U djangorestframework_simplejwt

    # Registering new user
    lets add a serializer.py in the core application
    add this to settings : 
    DJOSER = {
        'SERIALIZERS':{
            'user_create': 'core.serializers.UserCreateSerializer'
        }
    }
    
    # Building the Profile API
    # Logging in users -- AUTH users -- login endpoint -- jwt/create/ 
    docs --  djoser docs -- checkout access and refresh tokens
    jwt/create 
    -- storefront 
   access -- eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNjY0MTExNzIwLCJpYXQiOjE2NjM2Nzk3MjAsImp0aSI6ImRmZjk0NzRkMTllYzRlNTI5MDUzODJkMDk4N2E1MTcwIiwidXNlcl9pZCI6MX0.nJqHIV62cLVE4KX8wpjWkx_KNNMnNEjxLAKVC4oDdFk
   refresh -- eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTY2Mzc2NjEyMCwiaWF0IjoxNjYzNjc5NzIwLCJqdGkiOiJhYWE0YWMxNDJiMjM0NDNlYTljMDQwZTljOWJiMTY2MiIsInVzZXJfaWQiOjF9.U8Y8AOwrCWoQimqm6S4-GXNxBbzcHEmnvUUGoDtR4OY

   apitest
   access eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNjY0MTE1MzUyLCJpYXQiOjE2NjM2ODMzNTIsImp0aSI6ImMyYTMzYjM0ZTM3YzQ2OWU4M2FlNzQxODI0MTRmMjUxIiwidXNlcl9pZCI6NX0.pexzGShpvyIHGtPHLEJS7oARsDnT8HQNuH0xGg00do8

    # Inspecting json web tokens -- jwt.io
     
    # refreshing jwt token 
    jwt/refresh
    -- then we pass the refresh token

    # Getting the current user
    auth/users/me

    -- add mod header extension to chrome.
    
    -- get curent user profile or updating it 
        -- store/customers/me

    # Applying Permissions
    check drf docs permissions
    -- REST_FRAMEWORK = {
        'COERCE_DECIMAL_TO_STRING':False,
        'DEFAULT_AUTHENTICATION_CLASSES': (
            'rest_framework_simplejwt.authentication.JWTAuthentication',
        ),
        # this dictates the type of security but we can remove it and implement it to specific classes
        'DEFAULT_PERMISSION_CLASSES': [
            'rest_framework.permissions.IsAuthenticated'
        ]
    }

    # specific custom permissions
    # Profile API
class CustomerViewSet(CreateModelMixin, RetrieveModelMixin, UpdateModelMixin, GenericViewSet):
queryset = Customer.objects.all()
serializer_class = CustomerSerializer
# settting up permissions
permission_classes = [IsAuthenticated]

def get_permissions(self):
    if self.request.method == 'GET':
        return [AllowAny()]
    return [IsAuthenticated()]

# creating custom permissions
    -- we use the permission.py file to call the permissions

# Orders API
# Orders Endpoint
POST   /orders/         {cartId}  order
GET       /orders/      {}          order[]
GET       /orders/1     { }         order
PATCH     /orders/1   
DELETE     /orders/1  

# Creating an Order
# creating order items
# deleting a cart item order
# returning the created Order
# Data Validation -- invalid cart , empty order 

# django signals 
    -- pre_save
    -- post_save
    -- pre_delete
    -- post_delete