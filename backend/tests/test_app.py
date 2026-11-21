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
    assert len(client.get('/products').json()) == 12
    assert len(client.get('/products?q=nike').json()) >= 2
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


def test_almaty_stores_persist_and_cover_all_districts(context):
    client, _, module = context
    result = client.get('/stores')
    assert result.status_code == 200
    data = result.json()
    assert len(data) == 10
    assert all(s['is_demo'] is True for s in data)
    assert {s['district'] for s in data} == {
        'Almaly', 'Auezov', 'Bostandyk', 'Medeu',
        'Zhetysu', 'Turksib', 'Alatau', 'Nauryzbay',
    }
    assert len(client.get('/stores?district=Bostandyk').json()) == 2
    assert client.get('/stores/5').json()['district'] == 'Auezov'
    assert client.get('/stores/999').status_code == 404
    module.init_db()
    assert len(client.get('/stores').json()) == 10


def test_store_profiles_unique_inventory_and_restock_notifications(context):
    client, login, module = context
    customer = login('customer@demo.test')
    admin = login('admin@demo.test')
    stores = client.get('/stores').json()
    assert len(stores) == 10
    assert all(len(store['photos']) == 3 for store in stores)
    assert all(store['description'] and store['is_demo'] for store in stores)
    assert len(set(store['name'] for store in stores)) == 10
    catalog_1 = client.get('/stores/1/products').json()
    catalog_2 = client.get('/stores/2/products').json()
    assert len(catalog_1) == len(catalog_2) == 12
    assert [p['id'] for p in catalog_1] == [p['id'] for p in catalog_2]
    assert any(p1['sizes'] != p2['sizes'] for p1,p2 in zip(catalog_1, catalog_2))
    product = catalog_1[0]
    unavailable = [int(sz) for sz,n in product['sizes'].items() if n == 0]
    assert unavailable
    size = unavailable[0]
    result = client.post('/stores/1/restock-alerts', headers=customer,
                         json={'product_id': product['id'], 'size':size})
    assert result.status_code == 200, result.text
    assert len(client.get('/restock-alerts', headers=customer).json()) == 1
    assert client.post('/stores/1/restock-alerts', headers=admin,
                       json={'product_id':product['id'],'size':size}).status_code == 403
    supply = client.post('/admin/store-supplies', headers=admin, json={
        'store_id':1, 'product_id':product['id'],'size':size,'quantity':3})
    assert supply.status_code == 201, supply.text
    assert supply.json()['alerts_sent'] == 1
    assert client.get(f"/stores/1/products/{product['id']}").json()['sizes'][str(size)] == 3
    assert client.get('/restock-alerts', headers=customer).json() == []
    assert any(n['title']=='Size back in stock!'
               for n in client.get('/notifications',headers=customer).json())
    assert client.get(f"/stores/2/products/{product['id']}").json()['sizes'][str(size)] == catalog_2[0]['sizes'][str(size)]
    module.init_db()  # Reinitializing must not wipe branch-specific supplies.
    assert client.get(f"/stores/1/products/{product['id']}").json()['sizes'][str(size)] == 3


def test_branch_pickup_code_and_delivery_source_stock(context):
    client, login, _ = context
    customer = login('customer@demo.test')
    admin = login('admin@demo.test')
    branch = client.get('/stores/3/products').json()[0]
    size = next(int(k) for k,v in branch['sizes'].items() if v > 0)
    before = branch['sizes'][str(size)]
    missing = client.post('/orders',headers=customer,json={
        'store_id': 999,'fulfillment':'pickup',
        'items':[{'product_id':1,'size':size,'quantity':1}],
        'address':'Demo pickup contact test'})
    assert missing.status_code == 404
    order = client.post('/orders', headers=customer, json={
        'store_id':3,'fulfillment':'pickup',
        'items':[{'product_id':1,'size':size,'quantity':1}],
        'address':'Customer will collect in person'})
    assert order.status_code == 201, order.text
    oid = order.json()['id']
    assert order.json()['store_id'] == 3
    assert order.json()['fulfillment'] == 'pickup'
    assert order.json()['store_name'] == 'SneakerHub DISTRICT'
    current = client.get('/stores/3/products/1').json()
    assert current['sizes'][str(size)] == before - 1
    assert client.patch(f'/admin/orders/{oid}', headers=admin,
        json={'status':'preparing'}).status_code == 200
    assert client.patch(f'/admin/orders/{oid}', headers=admin,
        json={'status':'out_for_delivery','courier_id':3}).status_code == 409
    assert client.patch(f'/admin/orders/{oid}', headers=admin,
        json={'status':'ready_for_pickup'}).status_code == 200
    code_response = client.get(f'/orders/{oid}/delivery-code', headers=customer)
    assert code_response.status_code == 200
    code = code_response.json()['code']
    assert client.post(f'/admin/orders/{oid}/pickup', headers=customer,
        json={'code':code}).status_code == 403
    assert client.post(f'/admin/orders/{oid}/pickup', headers=admin,
        json={'code':'000000' if code!='000000' else '111111'}).status_code == 400
    confirmed = client.post(f'/admin/orders/{oid}/pickup', headers=admin,
        json={'code':code})
    assert confirmed.status_code == 200, confirmed.text
    assert client.get(f'/orders/{oid}', headers=customer).json()['status'] == 'delivered'
