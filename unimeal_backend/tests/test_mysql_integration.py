"""Integration tests against the real local MySQL schema; every test rolls back.

Run explicitly with UNIMEAL_TEST_MYSQL=1. No tables are created or dropped.
"""
import os
import secrets
from datetime import date, timedelta

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import func
from sqlalchemy.orm import Session

from app.auth import hash_password
from app.database import engine, get_db
from app.main import app
from app.models import Ingredient, Notification, Recipe, Role, User

pytestmark = pytest.mark.skipif(os.getenv('UNIMEAL_TEST_MYSQL') != '1', reason='Requires explicit local MySQL opt-in')


@pytest.fixture
def local_mysql():
    connection = engine.connect()
    transaction = connection.begin()
    def db_override():
        with Session(bind=connection, join_transaction_mode='create_savepoint') as db:
            yield db
    app.dependency_overrides[get_db] = db_override
    with Session(bind=connection, join_transaction_mode='create_savepoint') as db:
        suffix = secrets.token_hex(6)
        password = 'Integration-test-123!'
        accounts = {}
        for role in ['student', 'contributor', 'administrator']:
            user = User(role_id=db.query(Role).filter_by(role_name=role).one().role_id,
                        email=f'integration.{role}.{suffix}@unimeal.test',
                        password_hash=hash_password(password), display_name=f'Test {role}')
            db.add(user)
            db.flush()
            accounts[role] = (user.user_id, user.email)
        ingredient = db.query(Ingredient).filter(Ingredient.estimated_unit_cost > 0, Ingredient.is_active.is_(True)).first()
        ingredient_data = {'ingredientId': ingredient.ingredient_id, 'name': ingredient.ingredient_name,
                           'quantity': 10, 'unit': ingredient.default_measurement_unit.unit_symbol}
        unit_cost = float(ingredient.estimated_unit_cost)
        db.commit()
    try:
        with TestClient(app) as client:
            yield client, accounts, password, ingredient_data, unit_cost, connection
    finally:
        app.dependency_overrides.clear()
        transaction.rollback()
        connection.close()


def call(client, method, path, payload=None, status=200):
    response = client.request(method, '/api' + path, json=payload)
    assert response.status_code == status, (method, path, response.status_code, response.text)
    return response.json()


def login(client, accounts, password, role):
    return call(client, 'POST', '/auth/login', {'email': accounts[role][1], 'password': password})


def test_real_mysql_complete_flow(local_mysql):
    client, accounts, password, ingredient, unit_cost, connection = local_mysql
    call(client, 'GET', '/health')
    call(client, 'GET', '/dashboard', status=401)
    login(client, accounts, password, 'contributor')
    payload = {'title': 'Integration rice bowl', 'cuisine': 'Chinese', 'difficulty': 'Easy',
               'servings': 2, 'prepTime': 5, 'cookTime': 10, 'ingredientDetails': [ingredient],
               'steps': ['Cook and serve.'], 'dietaryTags': ['Vegetarian']}
    recipe = call(client, 'POST', '/recipes', payload, 201)
    rid = recipe['id']
    assert recipe['status'] == 'Draft'
    assert recipe['ingredientDetails'][0]['quantity'] == 10
    assert recipe['estimatedCost'] == round(round(10 * unit_cost, 2) / 2, 2)
    assert rid in [r['id'] for r in call(client, 'GET', '/my-recipes')]
    call(client, 'PUT', f'/recipes/{rid}', {'steps': ['Updated method.'], 'status': 'Published'})
    assert call(client, 'GET', f'/recipes/{rid}')['steps'] == ['Updated method.']
    with Session(bind=connection, join_transaction_mode='create_savepoint') as db:
        assert db.get(Recipe, rid).status == 'published'
        assert db.get(Recipe, rid).author_user_id == accounts['contributor'][0]
    call(client, 'POST', '/auth/logout')
    student = login(client, accounts, password, 'student')
    profile = call(client, 'PUT', '/profile', {**student, 'weeklyBudget': 55, 'allergies': ['Dairy'], 'dietaryPreferences': ['Vegetarian'], 'favouriteCuisines': ['Chinese']})
    assert profile['allergies'] == ['Dairy']
    assert call(client, 'GET', '/auth/me')['weeklyBudget'] == 55
    call(client, 'GET', '/admin/overview', status=403)
    call(client, 'PUT', f'/recipes/{rid}', {'title': 'Unauthorized edit'}, 403)
    assert call(client, 'POST', f'/recipes/{rid}/saved')['saved']
    assert rid in call(client, 'GET', '/saved-recipes')
    call(client, 'POST', f'/recipes/{rid}/ratings', {'rating': 4})
    rated = call(client, 'POST', f'/recipes/{rid}/ratings', {'rating': 5})
    assert rated['rating'] == 5 and rated['reviewCount'] == 1
    commented = call(client, 'POST', f'/recipes/{rid}/comments', {'text': 'A useful recipe.'}, 201)
    assert commented['comments'][0]['text'] == 'A useful recipe.'
    assert 'ingredientDetails' in commented
    entry = {'plannedDate': date.today().isoformat(), 'mealType': 'Dinner', 'recipeId': rid, 'plannedServings': 4}
    plan = call(client, 'POST', '/meal-plan/entries', entry)
    call(client, 'POST', '/meal-plan/entries', entry)
    assert len(call(client, 'GET', '/meal-plan')['entries']) == 1
    shopping = call(client, 'POST', '/shopping-list/generate')
    item = shopping['items'][0]
    assert item['totalQuantity'] == 20
    bought = call(client, 'PATCH', f"/shopping-list/items/{item['id']}/purchased")
    spent = bought['items'][0]['actualCost']
    assert spent == round(20 * unit_cost, 2)
    assert call(client, 'POST', '/shopping-list/generate')['items'][0]['purchased']
    assert call(client, 'GET', '/budget-summary')['actualSpent'] == spent
    dashboard = call(client, 'GET', '/dashboard')
    assert dashboard['tonight']['id'] == rid and dashboard['spent'] == spent
    assert rid in [r['id'] for r in dashboard['favourites']]
    report = call(client, 'POST', '/reports', {'targetType': 'Recipe', 'targetId': rid, 'reason': 'Test report'}, 201)
    with Session(bind=connection, join_transaction_mode='create_savepoint') as db:
        n = Notification(user_id=accounts['student'][0], notification_type='system', title='Test notification', message='Test')
        db.add(n)
        db.commit()
        nid = n.notification_id
    assert not call(client, 'GET', '/notifications')[0]['read']
    assert call(client, 'PATCH', f'/notifications/{nid}/read')['read']
    call(client, 'PATCH', '/notifications/read-all')
    recommendation = call(client, 'POST', '/recommendations', {'query': 'Vegetarian meals under $5'})
    assert recommendation['mode'] == 'local-rules'
    assert all(r['estimatedCost'] <= 5 for r in recommendation['recipes'])
    # A second student cannot see or mutate the first student's state.
    call(client, 'POST', '/auth/logout')
    second = call(client, 'POST', '/auth/register', {'name': 'Second student', 'email': f'second.{secrets.token_hex(6)}@unimeal.test', 'password': password}, 201)
    assert call(client, 'GET', '/meal-plan')['entries'] == []
    assert call(client, 'GET', '/saved-recipes') == []
    call(client, 'DELETE', f"/meal-plan/entries/{plan['entries'][0]['id']}", status=404)
    call(client, 'PATCH', f"/shopping-list/items/{item['id']}/purchased", status=404)
    call(client, 'PATCH', f'/notifications/{nid}/read', status=404)
    call(client, 'POST', '/auth/register', {'name': 'Bad role', 'email': 'bad-role@unimeal.test', 'password': password, 'role': 'administrator'}, 422)
    call(client, 'POST', '/auth/logout')
    login(client, accounts, password, 'administrator')
    result = call(client, 'GET', '/admin/overview')
    assert report['id'] in [r['id'] for r in result['reports']]
    reviewed = call(client, 'PATCH', f"/admin/reports/{report['id']}", {'status': 'Resolved'})
    assert next(r for r in reviewed['reports'] if r['id'] == report['id'])['status'] == 'Resolved'
    categories = call(client, 'POST', '/admin/ingredient-categories', {'name': f'Test {secrets.token_hex(6)}'}, 201)
    category = next(c for c in categories if c['name'].startswith('Test '))
    call(client, 'DELETE', f"/admin/ingredient-categories/{category['id']}")
    call(client, 'PATCH', f"/admin/users/{second['id']}", {'status': 'Suspended'})
    call(client, 'PATCH', f"/admin/users/{accounts['administrator'][0]}", {'status': 'Suspended'}, 409)
    call(client, 'GET', '/admin/management')
    call(client, 'PATCH', f'/admin/recipes/{rid}', {'status': 'Archived'})
    call(client, 'POST', '/auth/logout')
    login(client, accounts, password, 'student')
    call(client, 'GET', f'/recipes/{rid}', status=404)
    call(client, 'DELETE', f"/meal-plan/entries/{plan['entries'][0]['id']}")
    assert call(client, 'GET', '/meal-plan')['entries'] == []
    call(client, 'POST', '/auth/logout')
    login(client, accounts, password, 'contributor')
    call(client, 'DELETE', f'/recipes/{rid}')
    assert call(client, 'GET', '/my-recipes') == []
    call(client, 'POST', '/auth/logout')
    call(client, 'GET', '/auth/me', status=401)

def test_authentication_and_ownership(local_mysql):
    client, accounts, password, ingredient, _unit_cost, _connection = local_mysql
    call(client, 'POST', '/auth/login', {'email': accounts['student'][1], 'password': 'wrong'}, 401)
    call(client, 'POST', '/auth/register', {'name': 'Duplicate', 'email': accounts['student'][1], 'password': password}, 409)
    call(client, 'POST', '/auth/register', {'name': 'Short', 'email': 'short@unimeal.test', 'password': '123'}, 422)
    login(client, accounts, password, 'contributor')
    token = client.cookies.get('unimeal_session')
    rid = call(client, 'POST', '/recipes', {'title': 'Owned draft', 'cuisine': 'Chinese', 'ingredientDetails': [ingredient], 'steps': ['Cook.']}, 201)['id']
    other_email = f'other.contributor.{secrets.token_hex(6)}@unimeal.test'
    call(client, 'POST', '/auth/register', {'name': 'Other contributor', 'email': other_email, 'password': password, 'role': 'contributor'}, 201)
    call(client, 'GET', f'/recipes/{rid}', status=404)
    call(client, 'PUT', f'/recipes/{rid}', {'title': 'Not mine'}, 404)
    call(client, 'DELETE', f'/recipes/{rid}', status=404)
    call(client, 'POST', '/recipes', {'title': 'Invalid quantity', 'cuisine': 'Chinese', 'ingredientDetails': [{**ingredient, 'quantity': 0}]}, 422)
    call(client, 'POST', '/auth/logout')
    login(client, accounts, password, 'contributor')
    revoked = client.cookies.get('unimeal_session')
    call(client, 'POST', '/auth/logout')
    client.cookies.clear()
    assert client.get('/api/auth/me', headers={'Cookie': f'unimeal_session={revoked}'}).status_code == 401
    assert client.get('/api/auth/me', headers={'Cookie': f'unimeal_session={token[:-4]}xxxx'}).status_code == 401
    assert client.get('/api/auth/me', headers={'Cookie': 'unimeal_session=not-a-valid-token'}).status_code == 401


def test_spending_without_budget_and_after_plan_changes(local_mysql):
    client, accounts, password, ingredient, _unit_cost, _connection = local_mysql
    login(client, accounts, password, 'contributor')
    recipe = call(client, 'POST', '/recipes', {'title': 'Spending test', 'cuisine': 'Chinese', 'ingredientDetails': [ingredient], 'steps': ['Cook.']}, 201)
    call(client, 'PUT', f"/recipes/{recipe['id']}", {'status': 'Published'})
    call(client, 'POST', '/auth/logout')
    login(client, accounts, password, 'student')
    plan = call(client, 'POST', '/meal-plan/entries', {'plannedDate': date.today().isoformat(), 'mealType': 'Dinner', 'recipeId': recipe['id']})
    shopping = call(client, 'POST', '/shopping-list/generate')
    bought = call(client, 'PATCH', f"/shopping-list/items/{shopping['items'][0]['id']}/purchased")
    cost = bought['items'][0]['actualCost']
    summary = call(client, 'GET', '/budget-summary')
    assert summary['period']['budgetAmount'] == 0
    assert summary['actualSpent'] == cost and cost > 0
    call(client, 'DELETE', f"/meal-plan/entries/{plan['entries'][0]['id']}")
    call(client, 'POST', '/shopping-list/generate')
    assert call(client, 'GET', '/budget-summary')['actualSpent'] == cost
