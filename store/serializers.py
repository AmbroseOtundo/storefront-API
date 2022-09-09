from rest_framework import serializers
from decimal import Decimal
from store.models import Product, Collection

class CollectionSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField(max_length=255)


class ProductSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField(max_length=255)
    # source helps django look for the source of the price 
    # becuause in the product class we do not have the price and instead we have unit_price
    price = serializers.DecimalField(max_digits=6, decimal_places=2, source = 'unit_price') 
    # custome serializer
    price_with_tax = serializers.SerializerMethodField(method_name='calculate_tax')
    collection = serializers.HyperlinkedRelatedField(
        queryset=Collection.objects.all(),
        view_name='collection_detail'
    ) #

    # method to return price_with_tax
    def calculate_tax(self, product: Product):
        return product.unit_price * Decimal(1.1)