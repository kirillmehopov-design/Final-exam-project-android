"""SneakerHub educational FastAPI/SQLite backend.

Demo only. No payment processing, external push provider or GPS integration.
"""
from __future__ import annotations

from contextlib import asynccontextmanager, contextmanager
from datetime import datetime, timedelta, timezone
from hashlib import pbkdf2_hmac, sha256
import hmac
import os
from pathlib import Path
import secrets
import sqlite3
from typing import Iterator, Literal

from fastapi import Depends, FastAPI, Header, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field

DB_PATH = Path(os.environ.get('SNEAKERHUB_DB', str(Path(__file__).with_name('sneakerhub.sqlite3'))))
OTP_SECRET = os.environ.get('SNEAKERHUB_OTP_SECRET') or secrets.token_hex(32)
DEMO_PASS = 'DemoPass123!'

PRODUCTS = [
    (1, 'Air Jordan 1 High', 'Jordan', 'Lifestyle', 18999, 0,
     'Classic high-top basketball style with comfortable cushioning.',
     'https://images.unsplash.com/photo-1556906781-9a412961c28c?auto=format&fit=crop&w=900&q=80'),
    (2, 'Nike Air Max', 'Nike', 'Running', 15999, 15,
     'Everyday sneakers with lightweight support and visible Air cushioning.',
     'https://images.unsplash.com/photo-1542291026-7eec264c27ff?auto=format&fit=crop&w=900&q=80'),
    (3, 'Adidas Ultraboost', 'Adidas', 'Running', 17999, 0,
     'Responsive running shoes with a flexible upper.',
     'https://images.unsplash.com/photo-1608231387042-66d1773070a5?auto=format&fit=crop&w=900&q=80'),
    (4, 'New Balance 550', 'New Balance', 'Lifestyle', 13999, 0,
     'Retro court-inspired sneakers for everyday outfits.',
     'https://images.unsplash.com/photo-1539185441755-769473a23570?auto=format&fit=crop&w=900&q=80'),
    (5, 'Nike Dunk Low', 'Nike', 'Streetwear', 12999, 10,
     'Low-profile classic sneakers with a durable upper.',
     'https://images.unsplash.com/photo-1600269452121-4f2416e55c28?auto=format&fit=crop&w=900&q=80'),
    (6, 'Adidas Forum Low', 'Adidas', 'Lifestyle', 11999, 0,
     'Low-top basketball inspired vintage shoes.',
     'https://images.unsplash.com/photo-1518002171953-a080ee817e1f?auto=format&fit=crop&w=900&q=80'),
]


def utcnow() -> datetime:
    return datetime.now(timezone.utc)


def timestamp() -> str:
    return utcnow().isoformat()


@contextmanager
def db() -> Iterator[sqlite3.Connection]:
    connection = sqlite3.connect(DB_PATH, timeout=15)
    connection.row_factory = sqlite3.Row
    connection.execute('PRAGMA foreign_keys = ON')
    try:
        yield connection
        connection.commit()
    except Exception:
        connection.rollback()
        raise
    finally:
        connection.close()


def password_hash(password: str, salt: str | None = None) -> str:
    salt = salt or secrets.token_hex(16)
    derived = pbkdf2_hmac('sha256', password.encode(), bytes.fromhex(salt), 260000)
    return f'{salt}${derived.hex()}'


def verify_password(password: str, saved: str) -> bool:
    try:
        salt, stored = saved.split('$', 1)
        result = password_hash(password, salt).split('$', 1)[1]
        return hmac.compare_digest(result, stored)
    except (ValueError, TypeError):
        return False


def init_db() -> None:
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with db() as conn:
        conn.executescript('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY, email TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL, role TEXT NOT NULL DEFAULT 'customer',
            points INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS tokens (
            token_hash TEXT PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id),
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS products (
            id INTEGER PRIMARY KEY, name TEXT NOT NULL, brand TEXT NOT NULL,
            category TEXT NOT NULL, price_cents INTEGER NOT NULL,
            discount INTEGER NOT NULL DEFAULT 0, description TEXT NOT NULL,
            image_url TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS stock (
            product_id INTEGER NOT NULL REFERENCES products(id),
            size INTEGER NOT NULL, quantity INTEGER NOT NULL CHECK(quantity >= 0),
            PRIMARY KEY(product_id, size)
        );
        CREATE TABLE IF NOT EXISTS favorites (
            user_id INTEGER NOT NULL REFERENCES users(id),
            product_id INTEGER NOT NULL REFERENCES products(id),
            PRIMARY KEY(user_id, product_id)
        );
        CREATE TABLE IF NOT EXISTS orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id),
            courier_id INTEGER REFERENCES users(id),
            address TEXT NOT NULL, status TEXT NOT NULL,
            total_cents INTEGER NOT NULL, redeemed_points INTEGER NOT NULL DEFAULT 0,
            otp_expires TEXT, attempts INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS order_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL REFERENCES orders(id),
            product_id INTEGER NOT NULL REFERENCES products(id),
            size INTEGER NOT NULL, quantity INTEGER NOT NULL,
            price_cents INTEGER NOT NULL
        );
        CREATE TABLE IF NOT EXISTS supplies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            admin_id INTEGER NOT NULL REFERENCES users(id),
            product_id INTEGER NOT NULL REFERENCES products(id),
            size INTEGER NOT NULL, quantity INTEGER NOT NULL, created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id),
            title TEXT NOT NULL, message TEXT NOT NULL,
            is_read INTEGER NOT NULL DEFAULT 0, created_at TEXT NOT NULL
        );
        CREATE TABLE IF NOT EXISTS reviews (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id),
            product_id INTEGER NOT NULL REFERENCES products(id),
            rating INTEGER NOT NULL CHECK(rating BETWEEN 1 AND 5),
            comment TEXT NOT NULL, created_at TEXT NOT NULL,
            UNIQUE(user_id, product_id)
        );
        ''')
        for email, role in [
            ('customer@demo.test', 'customer'),
            ('courier@demo.test', 'courier'),
            ('admin@demo.test', 'admin'),
        ]:
            conn.execute('INSERT OR IGNORE INTO users (email,password_hash,role) VALUES (?,?,?)',
                         (email, password_hash(DEMO_PASS), role))
        for product in PRODUCTS:
            conn.execute('INSERT OR IGNORE INTO products '
                         '(id,name,brand,category,price_cents,discount,description,image_url) '
                         'VALUES (?,?,?,?,?,?,?,?)', product)
            for size in range(39, 46):
                conn.execute('INSERT OR IGNORE INTO stock (product_id,size,quantity) VALUES (?,?,?)',
                             (product[0], size, 7))


@asynccontextmanager
async def lifespan(_: FastAPI):
    init_db()
    yield


app = FastAPI(title='SneakerHub REST API', version='2.0', lifespan=lifespan)
app.add_middleware(CORSMiddleware, allow_origins=['*'], allow_methods=['*'], allow_headers=['*'])


class Credentials(BaseModel):
    email: str = Field(min_length=5, max_length=254)
    password: str = Field(min_length=8, max_length=128)


class OrderLine(BaseModel):
    product_id: int
    size: int = Field(ge=30, le=55)
    quantity: int = Field(ge=1, le=20)


class Checkout(BaseModel):
    items: list[OrderLine] = Field(min_length=1, max_length=30)
    address: str = Field(min_length=8, max_length=250)
    promo_code: str = ''
    use_points: bool = False


class OrderUpdate(BaseModel):
    status: Literal['preparing', 'out_for_delivery']
    courier_id: int | None = None


class CodeVerify(BaseModel):
    code: str = Field(pattern=r'^\d{6}$')


class Supply(BaseModel):
    product_id: int
    size: int = Field(ge=30, le=55)
    quantity: int = Field(ge=1, le=10000)


class Discount(BaseModel):
    percent: int = Field(ge=0, le=90)


class Review(BaseModel):
    rating: int = Field(ge=1, le=5)
    comment: str = Field(min_length=3, max_length=500)


def require_user(authorization: str | None = Header(default=None)) -> dict:
    if not authorization or not authorization.startswith('Bearer '):
        raise HTTPException(401, 'Login required')
    digest = sha256(authorization.removeprefix('Bearer ').encode()).hexdigest()
    with db() as conn:
        row = conn.execute('SELECT u.id,u.email,u.role,u.points FROM users u '
                           'JOIN tokens t ON t.user_id=u.id WHERE t.token_hash=?', (digest,)).fetchone()
        if row is None:
            raise HTTPException(401, 'Invalid session')
        return dict(row)


def require_role(*roles: str):
    def dependency(user: dict = Depends(require_user)) -> dict:
        if user['role'] not in roles:
            raise HTTPException(403, 'Not allowed for this role')
        return user
    return dependency


def notify(conn: sqlite3.Connection, user_id: int, title: str, message: str) -> None:
    conn.execute('INSERT INTO notifications(user_id,title,message,created_at) VALUES(?,?,?,?)',
                 (user_id, title, message, timestamp()))


def priced(row: sqlite3.Row) -> int:
    return (row['price_cents'] * (100 - row['discount'])) // 100


def product_dict(conn: sqlite3.Connection, row: sqlite3.Row) -> dict:
    result = dict(row)
    result['sale_price_cents'] = priced(row)
    result['sizes'] = {str(r['size']): r['quantity'] for r in conn.execute(
        'SELECT size,quantity FROM stock WHERE product_id=? ORDER BY size', (row['id'],))}
    rating = conn.execute('SELECT AVG(rating) AS value,COUNT(*) AS count FROM reviews '
                          'WHERE product_id=?', (row['id'],)).fetchone()
    result['rating'] = round(rating['value'], 1) if rating['value'] is not None else None
    result['review_count'] = rating['count']
    return result


def order_dict(conn: sqlite3.Connection, row: sqlite3.Row) -> dict:
    result = dict(row)
    result['items'] = [dict(x) for x in conn.execute('SELECT i.*,p.name,p.image_url FROM order_items i '
                  'JOIN products p ON p.id=i.product_id WHERE i.order_id=? ORDER BY i.id', (row['id'],))]
    return result


def visible_order(conn: sqlite3.Connection, order_id: int, user: dict) -> sqlite3.Row:
    row = conn.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
    if row is None:
        raise HTTPException(404, 'Order not found')
    if user['role'] != 'admin' and (row['user_id'] if user['role'] == 'customer' else row['courier_id']) != user['id']:
        raise HTTPException(403, 'Not your order')
    return row


@app.get('/health')
def health():
    return {'status': 'ok'}


@app.post('/auth/register', status_code=201)
def register(credentials: Credentials):
    email = credentials.email.strip().lower()
    if '@' not in email or '.' not in email.split('@')[-1]:
        raise HTTPException(422, 'Invalid email address')
    with db() as conn:
        try:
            conn.execute('INSERT INTO users(email,password_hash,role) VALUES(?,?,?)',
                         (email, password_hash(credentials.password), 'customer'))
        except sqlite3.IntegrityError:
            raise HTTPException(409, 'Email already registered')
    return login(credentials)


@app.post('/auth/login')
def login(credentials: Credentials):
    with db() as conn:
        row = conn.execute('SELECT * FROM users WHERE email=?', (credentials.email.strip().lower(),)).fetchone()
        if row is None or not verify_password(credentials.password, row['password_hash']):
            raise HTTPException(401, 'Wrong email or password')
        token = secrets.token_urlsafe(32)
        conn.execute('INSERT INTO tokens(token_hash,user_id,created_at) VALUES(?,?,?)',
                     (sha256(token.encode()).hexdigest(), row['id'], timestamp()))
        return {'token': token, 'user': {'id': row['id'], 'email': row['email'],
                                        'role': row['role'], 'points': row['points']}}


@app.post('/auth/logout')
def logout(user: dict = Depends(require_user), authorization: str = Header()):
    with db() as conn:
        conn.execute('DELETE FROM tokens WHERE token_hash=?',
                     (sha256(authorization.removeprefix('Bearer ').encode()).hexdigest(),))
    return {'ok': True}


@app.get('/me')
def me(user: dict = Depends(require_user)):
    return user


@app.get('/products')
def products(q: str = '', brand: str = '', category: str = '',
             max_price_cents: int | None = Query(default=None, ge=0)):
    with db() as conn:
        rows = conn.execute('SELECT * FROM products ORDER BY id').fetchall()
        result = [product_dict(conn, row) for row in rows]
        if q:
            result = [p for p in result if q.lower() in (p['name']+' '+p['brand']).lower()]
        if brand:
            result = [p for p in result if p['brand'].lower() == brand.lower()]
        if category:
            result = [p for p in result if p['category'].lower() == category.lower()]
        if max_price_cents is not None:
            result = [p for p in result if p['sale_price_cents'] <= max_price_cents]
        return result


@app.get('/products/{product_id}/reviews')
def reviews(product_id: int):
    with db() as conn:
        return [dict(r) for r in conn.execute('SELECT r.rating,r.comment,r.created_at,u.email '
                    'FROM reviews r JOIN users u ON u.id=r.user_id WHERE r.product_id=? '
                    'ORDER BY r.id DESC', (product_id,))]


@app.post('/products/{product_id}/reviews', status_code=201)
def add_review(product_id: int, review: Review, user: dict = Depends(require_role('customer'))):
    with db() as conn:
        purchased = conn.execute("SELECT 1 FROM order_items i JOIN orders o ON o.id=i.order_id "
                                 "WHERE o.user_id=? AND o.status='delivered' AND i.product_id=? LIMIT 1",
                                 (user['id'], product_id)).fetchone()
        if purchased is None:
            raise HTTPException(403, 'Review only after a delivered purchase')
        conn.execute('INSERT INTO reviews(user_id,product_id,rating,comment,created_at) VALUES(?,?,?,?,?) '
                     'ON CONFLICT(user_id,product_id) DO UPDATE SET rating=excluded.rating, '
                     'comment=excluded.comment,created_at=excluded.created_at',
                     (user['id'], product_id, review.rating, review.comment.strip(), timestamp()))
        return {'ok': True}


@app.get('/favorites')
def favorites(user: dict = Depends(require_role('customer'))):
    with db() as conn:
        return [r['product_id'] for r in conn.execute('SELECT product_id FROM favorites WHERE user_id=?',
                                                      (user['id'],))]


@app.post('/favorites/{product_id}')
def toggle_favorite(product_id: int, user: dict = Depends(require_role('customer'))):
    with db() as conn:
        if conn.execute('SELECT 1 FROM products WHERE id=?', (product_id,)).fetchone() is None:
            raise HTTPException(404, 'Unknown product')
        saved = conn.execute('SELECT 1 FROM favorites WHERE user_id=? AND product_id=?',
                             (user['id'], product_id)).fetchone()
        if saved:
            conn.execute('DELETE FROM favorites WHERE user_id=? AND product_id=?', (user['id'], product_id))
        else:
            conn.execute('INSERT INTO favorites(user_id,product_id) VALUES(?,?)', (user['id'], product_id))
        return {'favorite': not bool(saved)}


@app.post('/orders', status_code=201)
def checkout(request: Checkout, user: dict = Depends(require_role('customer'))):
    if not request.address.strip():
        raise HTTPException(422, 'Address is required')
    with db() as conn:
        conn.execute('BEGIN IMMEDIATE')
        subtotal = 0
        purchase: list[tuple[int, int, int, int]] = []
        quantities: dict[tuple[int, int], int] = {}
        for item in request.items:
            key = (item.product_id, item.size)
            quantities[key] = quantities.get(key, 0) + item.quantity
        if any(q > 20 for q in quantities.values()):
            raise HTTPException(422, 'Maximum 20 units of each size per order')
        for (product_id, size), quantity in quantities.items():
            row = conn.execute('SELECT * FROM products WHERE id=?', (product_id,)).fetchone()
            stock = conn.execute('SELECT quantity FROM stock WHERE product_id=? AND size=?',
                                 (product_id, size)).fetchone()
            if row is None or stock is None or stock['quantity'] < quantity:
                raise HTTPException(409, f'Not enough stock for product {product_id}, size {size}')
            unit_price = priced(row)
            subtotal += unit_price * quantity
            purchase.append((product_id, size, quantity, unit_price))
        coupon = request.promo_code.strip().upper()
        if coupon and coupon != 'WELCOME10':
            raise HTTPException(422, 'Unknown promo code')
        coupon_discount = subtotal // 10 if coupon == 'WELCOME10' else 0
        points = min(user['points'], (subtotal - coupon_discount) // 100) if request.use_points else 0
        total = subtotal - coupon_discount - points * 100
        conn.execute('UPDATE users SET points=points-? WHERE id=?', (points, user['id']))
        cursor = conn.execute('INSERT INTO orders(user_id,address,status,total_cents,redeemed_points,created_at) '
                              'VALUES(?,?,?,?,?,?)',
                              (user['id'], request.address.strip(), 'placed', total, points, timestamp()))
        order_id = cursor.lastrowid
        for pid, size, quantity, unit_price in purchase:
            conn.execute('UPDATE stock SET quantity=quantity-? WHERE product_id=? AND size=?',
                         (quantity, pid, size))
            conn.execute('INSERT INTO order_items(order_id,product_id,size,quantity,price_cents) '
                         'VALUES(?,?,?,?,?)', (order_id, pid, size, quantity, unit_price))
        notify(conn, user['id'], 'Order placed', f'Order #{order_id} was created successfully.')
        return order_dict(conn, conn.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone())


@app.get('/orders')
def list_orders(user: dict = Depends(require_user)):
    with db() as conn:
        if user['role'] == 'admin':
            rows = conn.execute('SELECT * FROM orders ORDER BY id DESC').fetchall()
        elif user['role'] == 'courier':
            rows = conn.execute('SELECT * FROM orders WHERE courier_id=? ORDER BY id DESC',
                                (user['id'],)).fetchall()
        else:
            rows = conn.execute('SELECT * FROM orders WHERE user_id=? ORDER BY id DESC',
                                (user['id'],)).fetchall()
        return [order_dict(conn, row) for row in rows]


@app.get('/orders/{order_id}')
def order_detail(order_id: int, user: dict = Depends(require_user)):
    with db() as conn:
        return order_dict(conn, visible_order(conn, order_id, user))


@app.get('/admin/couriers')
def couriers(_: dict = Depends(require_role('admin'))):
    with db() as conn:
        return [dict(r) for r in conn.execute("SELECT id,email FROM users WHERE role='courier'")]


@app.patch('/admin/orders/{order_id}')
def update_order(order_id: int, update: OrderUpdate, _: dict = Depends(require_role('admin'))):
    with db() as conn:
        row = conn.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone()
        if row is None:
            raise HTTPException(404, 'Order not found')
        if update.status == 'preparing' and row['status'] != 'placed':
            raise HTTPException(409, 'Order must be placed first')
        if update.status == 'out_for_delivery' and row['status'] != 'preparing':
            raise HTTPException(409, 'Order must be preparing first')
        if update.status == 'out_for_delivery':
            courier = conn.execute("SELECT id FROM users WHERE id=? AND role='courier'", (update.courier_id,)).fetchone()
            if courier is None:
                raise HTTPException(422, 'Choose a valid courier')
        conn.execute('UPDATE orders SET status=?,courier_id=COALESCE(?,courier_id) WHERE id=?',
                     (update.status, update.courier_id, order_id))
        notify(conn, row['user_id'], 'Order status', f'Order #{order_id}: {update.status}')
        return order_dict(conn, conn.execute('SELECT * FROM orders WHERE id=?', (order_id,)).fetchone())


def generate_code(order_id: int, expires: str) -> str:
    payload = f'{order_id}:{expires}'.encode()
    digest = hmac.new(OTP_SECRET.encode(), payload, 'sha256').digest()
    return f'{int.from_bytes(digest[:8], "big") % 1000000:06d}'


@app.post('/courier/orders/{order_id}/arrive')
def courier_arrive(order_id: int, user: dict = Depends(require_role('courier'))):
    with db() as conn:
        order = visible_order(conn, order_id, user)
        can_retry = (order['status'] == 'arrived' and order['otp_expires'] and
                     utcnow() >= datetime.fromisoformat(order['otp_expires']))
        if order['status'] != 'out_for_delivery' and not can_retry:
            raise HTTPException(409, 'Order is not out for delivery')
        expires = (utcnow() + timedelta(minutes=20)).isoformat()
        conn.execute("UPDATE orders SET status='arrived',otp_expires=?,attempts=0 WHERE id=?",
                     (expires, order_id))
        notify(conn, order['user_id'], 'Courier arrived',
               f'Your courier is nearby. Open order #{order_id} to view the delivery code.')
        return {'ok': True, 'expires_at': expires}


@app.get('/orders/{order_id}/delivery-code')
def delivery_code(order_id: int, user: dict = Depends(require_role('customer'))):
    with db() as conn:
        row = visible_order(conn, order_id, user)
        if row['status'] != 'arrived' or not row['otp_expires']:
            raise HTTPException(409, 'Delivery code is not ready')
        if utcnow() >= datetime.fromisoformat(row['otp_expires']):
            raise HTTPException(410, 'Code expired. Ask courier to resend arrival notification.')
        return {'code': generate_code(order_id, row['otp_expires']),
                'expires_at': row['otp_expires']}


@app.post('/courier/orders/{order_id}/deliver')
def courier_deliver(order_id: int, request: CodeVerify,
                    user: dict = Depends(require_role('courier'))):
    with db() as conn:
        conn.execute('BEGIN IMMEDIATE')
        row = visible_order(conn, order_id, user)
        if row['status'] != 'arrived':
            raise HTTPException(409, 'Courier has not marked arrival')
        if row['attempts'] >= 5:
            raise HTTPException(429, 'Too many attempts, contact admin')
        if not row['otp_expires'] or utcnow() >= datetime.fromisoformat(row['otp_expires']):
            raise HTTPException(410, 'Code expired')
        expected = generate_code(order_id, row['otp_expires'])
        if not hmac.compare_digest(request.code, expected):
            conn.execute('UPDATE orders SET attempts=attempts+1 WHERE id=?', (order_id,))
            # HTTPException inside a transactional context rolls back writes;
            # raise after commit so attempt count is retained.
            conn.commit()
            raise HTTPException(400, 'Incorrect delivery code')
        conn.execute("UPDATE orders SET status='delivered',otp_expires=NULL WHERE id=?", (order_id,))
        gained = row['total_cents'] // 1000  # 1 point per $10 spent
        conn.execute('UPDATE users SET points=points+? WHERE id=?', (gained, row['user_id']))
        notify(conn, row['user_id'], 'Order delivered',
               f'Order #{order_id} delivered. You earned {gained} loyalty points!')
        return {'ok': True, 'points_earned': gained}


@app.get('/notifications')
def notifications(user: dict = Depends(require_user)):
    with db() as conn:
        return [dict(r) for r in conn.execute('SELECT * FROM notifications WHERE user_id=? '
                                              'ORDER BY id DESC LIMIT 100', (user['id'],))]


@app.post('/notifications/{notification_id}/read')
def mark_read(notification_id: int, user: dict = Depends(require_user)):
    with db() as conn:
        result = conn.execute('UPDATE notifications SET is_read=1 WHERE id=? AND user_id=?',
                              (notification_id, user['id']))
        if result.rowcount == 0:
            raise HTTPException(404, 'Notification not found')
        return {'ok': True}


@app.post('/admin/supplies', status_code=201)
def add_supply(supply: Supply, user: dict = Depends(require_role('admin'))):
    with db() as conn:
        if conn.execute('SELECT 1 FROM products WHERE id=?', (supply.product_id,)).fetchone() is None:
            raise HTTPException(404, 'Unknown product')
        conn.execute('INSERT INTO stock(product_id,size,quantity) VALUES(?,?,?) '
                     'ON CONFLICT(product_id,size) DO UPDATE SET quantity=quantity+excluded.quantity',
                     (supply.product_id, supply.size, supply.quantity))
        conn.execute('INSERT INTO supplies(admin_id,product_id,size,quantity,created_at) '
                     'VALUES(?,?,?,?,?)',
                     (user['id'], supply.product_id, supply.size, supply.quantity, timestamp()))
        return {'ok': True}


@app.get('/admin/supplies')
def supply_history(_: dict = Depends(require_role('admin'))):
    with db() as conn:
        return [dict(r) for r in conn.execute('SELECT * FROM supplies ORDER BY id DESC')]


@app.patch('/admin/products/{product_id}/discount')
def set_discount(product_id: int, discount: Discount,
                 _: dict = Depends(require_role('admin'))):
    with db() as conn:
        row = conn.execute('SELECT * FROM products WHERE id=?', (product_id,)).fetchone()
        if row is None:
            raise HTTPException(404, 'Product not found')
        conn.execute('UPDATE products SET discount=? WHERE id=?', (discount.percent, product_id))
        if discount.percent > row['discount']:
            watchers = conn.execute('SELECT user_id FROM favorites WHERE product_id=?',
                                    (product_id,)).fetchall()
            for watcher in watchers:
                notify(conn, watcher['user_id'], 'Price drop!',
                       f'{row["name"]} now has {discount.percent}% off.')
        return product_dict(conn, conn.execute('SELECT * FROM products WHERE id=?', (product_id,)).fetchone())


@app.get('/admin/stats')
def stats(_: dict = Depends(require_role('admin'))):
    with db() as conn:
        orders = conn.execute('SELECT COUNT(*) AS count FROM orders').fetchone()['count']
        revenue = conn.execute("SELECT COALESCE(SUM(total_cents),0) AS total FROM orders WHERE status='delivered'").fetchone()['total']
        low_stock = conn.execute('SELECT COUNT(*) AS count FROM stock WHERE quantity < 3').fetchone()['count']
        return {'orders': orders, 'revenue_cents': revenue, 'low_stock_variants': low_stock}
