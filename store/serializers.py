from rest_framework import serializers
from store.models import Product

class ProductSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    title = serializers.CharField(max_length=255)
    unit_price = serializers.DecimalField(max_digits=6, decimal_places=2)
    # custome serializer
    price_with_tax = serializers.SerializerMethodField(method_name='calculat_tax')
    # method to return price_with_tax
    def calculate_tax(self, product: Product):
        return product.unit_price * 1.1