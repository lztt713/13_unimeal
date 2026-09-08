"""Password hashing and signed HttpOnly sessions without adding database tables."""
import base64
import hashlib
import hmac
import os
import secrets
import time

import bcrypt
from fastapi import Depends, HTTPException, Request, Response
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User

COOKIE = 'unimeal_session'
SESSION_SECONDS = 60 * 60 * 24 * 7
# Local development remains usable without configuration; launch script persists a secret.
SECRET = os.getenv('SESSION_SECRET') or secrets.token_urlsafe(48)
_revoked = {}


def hash_password(password: str) -> str:
    salt = secrets.token_hex(16)
    digest = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), 600000)
    return f'pbkdf2_sha256$600000${salt}${digest.hex()}'


def verify_password(password: str, encoded: str) -> bool:
    try:
        if encoded.startswith(('$2a$', '$2b$', '$2y$')):
            return bcrypt.checkpw(password.encode(), encoded.encode())
        kind, iterations, salt, digest = encoded.split('$')
        if kind != 'pbkdf2_sha256':
            return False
        actual = hashlib.pbkdf2_hmac('sha256', password.encode(), salt.encode(), int(iterations)).hex()
        return hmac.compare_digest(actual, digest)
    except (ValueError, TypeError):
        return False


def set_session(response: Response, user: User):
    payload = f'{user.user_id}:{int(time.time()) + SESSION_SECONDS}:{secrets.token_hex(16)}'
    signature = hmac.new(SECRET.encode(), payload.encode(), hashlib.sha256).hexdigest()
    token = base64.urlsafe_b64encode(f'{payload}:{signature}'.encode()).decode()
    response.set_cookie(COOKIE, token, max_age=SESSION_SECONDS, httponly=True,
                        samesite='lax', secure=os.getenv('COOKIE_SECURE') == 'true', path='/api')


def get_current_user(request: Request, db: Session = Depends(get_db)) -> User:
    token = request.cookies.get(COOKIE, '')
    try:
        uid, expires, nonce, signature = base64.urlsafe_b64decode(token).decode().split(':')
        expected = hmac.new(SECRET.encode(), f'{uid}:{expires}:{nonce}'.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(expected, signature) or int(expires) <= time.time() or token in _revoked:
            raise ValueError()
        user = db.get(User, int(uid))
        if user is None or not user.is_active:
            raise ValueError()
        return user
    except (ValueError, UnicodeError, TypeError):
        raise HTTPException(401, 'Please sign in to continue') from None


def clear_session(request: Request, response: Response):
    now = time.time()
    for token, expiry in list(_revoked.items()):
        if expiry <= now:
            _revoked.pop(token, None)
    token = request.cookies.get(COOKIE)
    if token:
        _revoked[token] = now + SESSION_SECONDS
    response.delete_cookie(COOKIE, path='/api')


def require_role(*roles):
    def dependency(user: User = Depends(get_current_user)):
        if user.role.role_name not in roles:
            raise HTTPException(403, 'This action is not available for your account role')
        return user
    return dependency


student_user = require_role('student')
contributor_user = require_role('contributor')
admin_user = require_role('administrator')
