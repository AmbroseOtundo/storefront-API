from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response # this is for the API

@api_view()
def product_list(request):
    return Response('ok')


@api_view()
def product_detail(request, id):
    return Response('ok')

