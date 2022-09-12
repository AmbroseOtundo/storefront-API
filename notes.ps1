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