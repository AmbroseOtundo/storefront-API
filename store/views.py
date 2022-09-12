import collections
from django.shortcuts import get_object_or_404
from rest_framework.decorators import api_view
from django.db.models.aggregates import Count
from rest_framework import status
from rest_framework.response import Response # this is for the API
from  .models import Collection, Product
from .serializers import ProductSerializer, CollectionSerializer


@api_view(['GET', 'POST'])
def product_list(request):
    if request.method == 'GET':
        # this prevents lazy loading. ref in serializer collection object
        queryset = Product.objects.select_related('collection').all() 
        serializer = ProductSerializer(queryset, many=True, context={'request':request})
        return Response(serializer.data)
    # This is the POST method. It is creating a new product.
    elif request.method == 'POST':
        serializer = ProductSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)


# If the request is a GET, return the product with the given id. If the request is a PUT, update the
# product with the given id
@api_view(['GET', 'PUT', 'DELETE'])
def product_detail(request, id):
    product = get_object_or_404(Product, pk=id)
    if request.method == 'GET':        
        serializer = ProductSerializer(product)
        return Response(serializer.data)
    elif request.method == 'PUT':
        serializer = ProductSerializer(Product, data=request.data)
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(serializer.data)
    elif request.method == 'DELETE':
        # This is checking if the product has any order items. If it does, it returns a 405 error.
        if product.orderitems.count() > 0:
            return Response({'error':'Product cannot be deleted because it is associated with another product'},status=status.HTTP_405_METHOD_NOT_ALLOWED)
        product.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)

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


