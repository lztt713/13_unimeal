"""Create a local account without changing existing accounts or the schema."""
import argparse
from getpass import getpass
from sqlalchemy import func
from app.auth import hash_password
from app.database import SessionLocal
from app.models import Role, User


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--email', required=True)
    parser.add_argument('--name', required=True)
    parser.add_argument('--role', choices=['student', 'contributor', 'administrator'], default='administrator')
    args = parser.parse_args()
    password = getpass('New account password (at least 8 characters): ')
    if len(password) < 8 or len(password) > 128:
        raise SystemExit('Password must be 8-128 characters.')
    with SessionLocal() as db:
        if db.query(User).filter(func.lower(User.email) == args.email.strip().lower()).first():
            raise SystemExit('This email already exists; existing accounts are not modified.')
        role = db.query(Role).filter(Role.role_name == args.role).one()
        db.add(User(role_id=role.role_id, email=args.email.strip().lower(), display_name=args.name.strip(), password_hash=hash_password(password)))
        db.commit()
    print('Account created. Sign in using the supplied email and password.')


if __name__ == '__main__':
    main()
