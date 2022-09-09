import http
from http.client import HTTPResponse
from django.shortcuts import render
from django.http import HTTPResponse

def product_list():
    return HTTPResponse('ok')

