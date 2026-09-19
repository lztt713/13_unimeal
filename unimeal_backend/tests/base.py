"""MySQL-backed test base (张展赫 ZZH).

Tests run against a dedicated ``unimeal_test`` database so the development
database (``unimeal_planner``) and its sample data are never touched.

数据库测试基类：跑在独立的 unimeal_test 库上，绝不污染开发库 unimeal_planner。
每个测试方法前重建表结构，保证用例之间互不影响、计数确定。
"""

from __future__ import annotations

import os
import unittest

from sqlalchemy import create_engine, text
from sqlalchemy.engine import make_url
from sqlalchemy.orm import sessionmaker

from app.database import Base

# ZZH: 测试库连接串，可通过环境变量 TEST_DATABASE_URL 覆盖（密码写在这里或 .env）。
TEST_DATABASE_URL = os.getenv(
    "TEST_DATABASE_URL",
    "mysql+pymysql://root:password@127.0.0.1:3306/unimeal_test?charset=utf8mb4",
)


def ensure_test_database() -> None:
    """Create the test database if it does not exist yet.

    Uses a raw PyMySQL connection without selecting a database, because
    ``URL.set(database=None)`` does not actually clear the database in
    SQLAlchemy 2.0 and would fail with "Unknown database".
    """
    import pymysql

    url = make_url(TEST_DATABASE_URL)
    connection = pymysql.connect(
        host=url.host,
        port=url.port or 3306,
        user=url.username,
        password=url.password,
        charset="utf8mb4",
    )
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                f"CREATE DATABASE IF NOT EXISTS `{url.database}` "
                "CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
            )
        connection.commit()
    finally:
        connection.close()


def _reset_schema(engine) -> None:
    """Drop and recreate all ORM tables, ignoring foreign keys while dropping.

    在同一个连接里关闭外键检查后 drop_all + create_all，避免 MySQL 因外键拒绝删表。
    """
    with engine.connect() as conn:
        conn.execute(text("SET FOREIGN_KEY_CHECKS=0"))
        conn.commit()
        Base.metadata.drop_all(bind=conn)
        Base.metadata.create_all(bind=conn)
        conn.execute(text("SET FOREIGN_KEY_CHECKS=1"))
        conn.commit()


class MySQLTestCase(unittest.TestCase):
    """Base class: gives every test a fresh, empty MySQL schema."""

    @classmethod
    def setUpClass(cls):
        ensure_test_database()
        cls.engine = create_engine(TEST_DATABASE_URL, pool_pre_ping=True)
        cls.Session = sessionmaker(bind=cls.engine)

    def setUp(self):
        _reset_schema(self.engine)
        self.db = self.Session()

    def tearDown(self):
        self.db.close()

    @classmethod
    def tearDownClass(cls):
        Base.metadata.drop_all(cls.engine)
        cls.engine.dispose()
