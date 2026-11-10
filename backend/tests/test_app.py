import importlib
import os
from pathlib import Path

import pytest
from fastapi.testclient import TestClient


@pytest.fixture()
def context(tmp_path: Path, monkeypatch):
    monkeypatch.setenv('SNEAKERHUB_DB', str(tmp_path / 'test.sqlite3'))
    monkeypatch.setenv('SNEAKERHUB_OTP_SECRET', 'test-key-do-not-use-in-production')
    from backend import app as module
    module = importlib.reload(module)
    with TestClient(module.app) as client:
        def login(email):
            response = client.post('/auth/login', json={'email': email, 'password': 'DemoPass123!'})
            assert response.status_code == 200, response.text
            return {'Authorization': 'Bearer ' + response.json()['token']}
        yield client, login, module


def test_customer_to_courier_delivery_flow(context):
    client, login, _ = context
    cust = login('customer@demo.test')
    admin = login('admin@demo.test')
    courier = login('courier@demo.test')
    assert len(client.get('/products').json()) == 6
    assert len(client.get('/products?q=nike').json()) == 2
    p = client.get('/products').json()[0]
    size = 42
    before = p['sizes'][str(size)]
    assert client.post('/favorites/1', headers=cust).json()['favorite'] is True
    checkout = client.post('/orders', headers=cust, json={
        'items': [{'product_id': 1, 'size': size, 'quantity': 2}],
        'address': '123 Demo Street, Almaty', 'promo_code': 'WELCOME10',
    })
    assert checkout.status_code == 201, checkout.text
    order = checkout.json()
    oid = order['id']
    assert order['total_cents'] == (p['sale_price_cents'] * 2) - (p['sale_price_cents'] * 2) // 10
    assert client.get('/products').json()[0]['sizes'][str(size)] == before - 2
    assert client.get('/orders', headers=cust).json()[0]['id'] == oid
    assert client.get('/orders', headers=courier).json() == []
    assert client.post(f'/courier/orders/{oid}/arrive', headers=courier).status_code == 403
    assert client.patch(f'/admin/orders/{oid}', headers=cust,
                        json={'status':'preparing'}).status_code == 403
    assert client.patch(f'/admin/orders/{oid}', headers=admin,
                        json={'status':'preparing'}).status_code == 200
    couriers = client.get('/admin/couriers', headers=admin).json()
    courier_id = couriers[0]['id']
    assert client.patch(f'/admin/orders/{oid}', headers=admin, json={
        'status': 'out_for_delivery', 'courier_id': courier_id}).status_code == 200
    arrived = client.post(f'/courier/orders/{oid}/arrive', headers=courier)
    assert arrived.status_code == 200
    assert client.get(f'/orders/{oid}/delivery-code', headers=courier).status_code == 403
    code_resp = client.get(f'/orders/{oid}/delivery-code', headers=cust)
    assert code_resp.status_code == 200
    code = code_resp.json()['code']
    assert len(code) == 6
    wrong = client.post(f'/courier/orders/{oid}/deliver', headers=courier, json={'code': '999999' if code != '999999' else '000000'})
    assert wrong.status_code == 400
    done = client.post(f'/courier/orders/{oid}/deliver', headers=courier, json={'code': code})
    assert done.status_code == 200, done.text
    assert client.get(f'/orders/{oid}', headers=cust).json()['status'] == 'delivered'
    assert client.get('/me', headers=cust).json()['points'] == done.json()['points_earned']
    assert client.get('/admin/stats', headers=admin).json()['revenue_cents'] == order['total_cents']
    assert client.post('/products/1/reviews', headers=cust,
                       json={'rating':5,'comment':'Very comfortable sneakers'}).status_code == 201
    assert len(client.get('/products/1/reviews').json()) == 1
    assert len(client.get('/notifications', headers=cust).json()) >= 3


def test_stock_discount_notification_and_permissions(context):
    client, login, _ = context
    cust, admin, courier = [login(x) for x in
                           ('customer@demo.test', 'admin@demo.test', 'courier@demo.test')]
    assert client.post('/admin/supplies', headers=cust,
                       json={'product_id': 2, 'size': 41, 'quantity': 5}).status_code == 403
    before = client.get('/products').json()[1]['sizes']['41']
    assert client.post('/admin/supplies', headers=admin,
                       json={'product_id': 2, 'size': 41, 'quantity': 5}).status_code == 201
    assert client.get('/products').json()[1]['sizes']['41'] == before+5
    assert client.post('/favorites/2', headers=cust).status_code == 200
    assert client.patch('/admin/products/2/discount', headers=admin,
                        json={'percent':25}).status_code == 200
    assert 'Price drop!' in [n['title'] for n in client.get('/notifications', headers=cust).json()]
    assert client.get('/admin/stats', headers=courier).status_code == 403
    assert client.post('/orders', headers=cust, json={
        'items':[{'product_id':2,'size':41,'quantity':999}],
        'address':'A valid customer delivery address'}).status_code == 422
    assert client.post('/products/2/reviews', headers=cust,
                       json={'rating':5,'comment':'Not purchased yet'}).status_code == 403


def test_register_and_overselling(context):
    client, login, _ = context
    response = client.post('/auth/register', json={
        'email':'new@narxoz.kz','password':'SomeLongPassword!'})
    assert response.status_code == 201
    token = response.json()['token']
    assert response.json()['user']['role'] == 'customer'
    headers = {'Authorization':'Bearer '+token}
    request = {'items':[{'product_id':3,'size':39,'quantity':6}],
               'address':'Test customer address 123'}
    assert client.post('/orders', headers=headers, json=request).status_code == 201
    assert client.post('/orders', headers=headers, json=request).status_code == 409
    assert client.post('/auth/logout', headers=headers).status_code == 200
    assert client.get('/me', headers=headers).status_code == 401
