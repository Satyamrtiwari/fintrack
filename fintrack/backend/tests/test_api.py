import pytest
from datetime import date
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

from app.main import app, seed_default_categories
from app.database import Base, get_db

# Create an in-memory SQLite database specifically for test isolation
SQLALCHEMY_DATABASE_URL = "sqlite:///:memory:"

engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


@pytest.fixture(scope="session", autouse=True)
def setup_database():
    Base.metadata.create_all(bind=engine)
    db = TestingSessionLocal()
    seed_default_categories(db)
    db.close()
    yield
    Base.metadata.drop_all(bind=engine)


@pytest.fixture()
def db_session():
    connection = engine.connect()
    transaction = connection.begin()
    session = TestingSessionLocal(bind=connection)
    yield session
    session.close()
    transaction.rollback()
    connection.close()


@pytest.fixture()
def client(db_session):
    def override_get_db():
        try:
            yield db_session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    with TestClient(app) as test_client:
        yield test_client
    app.dependency_overrides.clear()


# Helper to register and return auth header
def get_auth_header(client: TestClient, name: str, email: str, password: str = "securepass123"):
    response = client.post("/api/auth/register", json={
        "name": name,
        "email": email,
        "password": password
    })
    assert response.status_code == 201, response.text
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


class TestAuthentication:
    def test_register_success(self, client):
        res = client.post("/api/auth/register", json={
            "name": "Alice Green",
            "email": "alice@example.com",
            "password": "mypassword123"
        })
        assert res.status_code == 201
        data = res.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert data["user"]["email"] == "alice@example.com"
        assert data["user"]["name"] == "Alice Green"

    def test_register_duplicate_email(self, client):
        client.post("/api/auth/register", json={
            "name": "Duplicate User",
            "email": "dup@example.com",
            "password": "password123"
        })
        res = client.post("/api/auth/register", json={
            "name": "Duplicate User 2",
            "email": "dup@example.com",
            "password": "password456"
        })
        assert res.status_code == 400
        assert "already exists" in res.json()["detail"]

    def test_register_invalid_data(self, client):
        # Short password
        res = client.post("/api/auth/register", json={
            "name": "Short Pwd",
            "email": "short@example.com",
            "password": "123"
        })
        assert res.status_code == 422

        # Invalid email
        res = client.post("/api/auth/register", json={
            "name": "Bad Email",
            "email": "not-an-email",
            "password": "password123"
        })
        assert res.status_code == 422

    def test_login_success(self, client):
        client.post("/api/auth/register", json={
            "name": "Bob Blue",
            "email": "bob@example.com",
            "password": "bobpassword123"
        })
        res = client.post("/api/auth/login", json={
            "email": "bob@example.com",
            "password": "bobpassword123"
        })
        assert res.status_code == 200
        assert "access_token" in res.json()
        assert res.json()["user"]["email"] == "bob@example.com"

    def test_login_invalid_password(self, client):
        res = client.post("/api/auth/login", json={
            "email": "bob@example.com",
            "password": "wrongpassword"
        })
        assert res.status_code == 401

    def test_get_current_user_profile(self, client):
        headers = get_auth_header(client, "Charlie", "charlie@example.com")
        res = client.get("/api/auth/me", headers=headers)
        assert res.status_code == 200
        assert res.json()["email"] == "charlie@example.com"

    def test_unauthorized_without_token(self, client):
        res = client.get("/api/auth/me")
        assert res.status_code == 403 or res.status_code == 401


class TestTransactions:
    def test_create_and_read_transactions(self, client):
        headers = get_auth_header(client, "Trader", "trader@example.com")

        # Create income
        res1 = client.post("/api/transactions", headers=headers, json={
            "title": "Monthly Salary",
            "amount": 5000.00,
            "type": "income",
            "category": "Salary",
            "transaction_date": str(date.today()),
            "notes": "Direct deposit"
        })
        assert res1.status_code == 201
        t1 = res1.json()
        assert t1["amount"] == 5000.00
        assert t1["type"] == "income"

        # Create expense
        res2 = client.post("/api/transactions", headers=headers, json={
            "title": "Grocery Shopping",
            "amount": 150.50,
            "type": "expense",
            "category": "Food & Dining",
            "transaction_date": str(date.today()),
            "notes": "Supermarket"
        })
        assert res2.status_code == 201
        t2 = res2.json()

        # List transactions
        list_res = client.get("/api/transactions", headers=headers)
        assert list_res.status_code == 200
        data = list_res.json()
        assert data["total"] == 2
        assert len(data["transactions"]) == 2

    def test_update_transaction(self, client):
        headers = get_auth_header(client, "Updater", "updater@example.com")
        res = client.post("/api/transactions", headers=headers, json={
            "title": "Gym Membership",
            "amount": 50.00,
            "type": "expense",
            "category": "Health & Medical",
            "transaction_date": str(date.today())
        })
        t_id = res.json()["id"]

        # Update amount and title
        up_res = client.put(f"/api/transactions/{t_id}", headers=headers, json={
            "title": "Annual Gym Membership",
            "amount": 55.00
        })
        assert up_res.status_code == 200
        assert up_res.json()["title"] == "Annual Gym Membership"
        assert up_res.json()["amount"] == 55.00

    def test_delete_transaction(self, client):
        headers = get_auth_header(client, "Deleter", "deleter@example.com")
        res = client.post("/api/transactions", headers=headers, json={
            "title": "Coffee",
            "amount": 4.50,
            "type": "expense",
            "category": "Food & Dining",
            "transaction_date": str(date.today())
        })
        t_id = res.json()["id"]

        del_res = client.delete(f"/api/transactions/{t_id}", headers=headers)
        assert del_res.status_code == 200

        # Try to get deleted transaction
        get_res = client.get(f"/api/transactions/{t_id}", headers=headers)
        assert get_res.status_code == 404

    def test_user_data_isolation(self, client):
        """User A must not be able to read, update or delete User B's transactions."""
        user_a_headers = get_auth_header(client, "User A", "usera@example.com")
        user_b_headers = get_auth_header(client, "User B", "userb@example.com")

        # User A creates a transaction
        res = client.post("/api/transactions", headers=user_a_headers, json={
            "title": "Secret Expense",
            "amount": 999.00,
            "type": "expense",
            "category": "Shopping",
            "transaction_date": str(date.today())
        })
        t_id = res.json()["id"]

        # User B tries to view it
        get_res = client.get(f"/api/transactions/{t_id}", headers=user_b_headers)
        assert get_res.status_code == 404

        # User B tries to update it
        put_res = client.put(f"/api/transactions/{t_id}", headers=user_b_headers, json={
            "title": "Hacked Transaction"
        })
        assert put_res.status_code == 404

        # User B tries to delete it
        del_res = client.delete(f"/api/transactions/{t_id}", headers=user_b_headers)
        assert del_res.status_code == 404

        # User B's transaction list should not contain User A's transaction
        list_res = client.get("/api/transactions", headers=user_b_headers)
        assert list_res.json()["total"] == 0

    def test_transaction_validation_errors(self, client):
        headers = get_auth_header(client, "Validator", "validator@example.com")

        # Negative amount
        res = client.post("/api/transactions", headers=headers, json={
            "title": "Invalid Amount",
            "amount": -100.0,
            "type": "expense",
            "category": "Food & Dining",
            "transaction_date": str(date.today())
        })
        assert res.status_code == 422

        # Invalid type
        res = client.post("/api/transactions", headers=headers, json={
            "title": "Invalid Type",
            "amount": 100.0,
            "type": "transfer",
            "category": "Other",
            "transaction_date": str(date.today())
        })
        assert res.status_code == 422


class TestAnalytics:
    def test_analytics_calculations(self, client):
        headers = get_auth_header(client, "Analyst", "analyst@example.com")

        # Add 2 incomes: 3000 + 1000 = 4000
        client.post("/api/transactions", headers=headers, json={
            "title": "Main Job", "amount": 3000.00, "type": "income",
            "category": "Salary", "transaction_date": str(date.today())
        })
        client.post("/api/transactions", headers=headers, json={
            "title": "Freelance Gig", "amount": 1000.00, "type": "income",
            "category": "Freelance", "transaction_date": str(date.today())
        })

        # Add 2 expenses: 500 (Food) + 300 (Transport) = 800
        client.post("/api/transactions", headers=headers, json={
            "title": "Groceries", "amount": 500.00, "type": "expense",
            "category": "Food & Dining", "transaction_date": str(date.today())
        })
        client.post("/api/transactions", headers=headers, json={
            "title": "Gas", "amount": 300.00, "type": "expense",
            "category": "Transportation", "transaction_date": str(date.today())
        })

        # 1. Summary
        sum_res = client.get("/api/analytics/summary", headers=headers)
        assert sum_res.status_code == 200
        s = sum_res.json()
        assert s["total_income"] == 4000.00
        assert s["total_expenses"] == 800.00
        assert s["net_savings"] == 3200.00
        assert s["savings_rate"] == 80.00  # (3200 / 4000) * 100
        assert s["transaction_count"] == 4

        # 2. Monthly
        month_res = client.get("/api/analytics/monthly?months=6", headers=headers)
        assert month_res.status_code == 200
        m_data = month_res.json()["monthly_data"]
        assert len(m_data) > 0
        latest_month = m_data[-1]
        assert latest_month["income"] == 4000.00
        assert latest_month["expense"] == 800.00
        assert latest_month["net"] == 3200.00

        # 3. Categories
        cat_res = client.get("/api/analytics/categories", headers=headers)
        assert cat_res.status_code == 200
        cats = cat_res.json()
        assert len(cats["expense_categories"]) == 2
        # Food is 500 out of 800 -> 62.5%
        food_cat = next(c for c in cats["expense_categories"] if c["category"] == "Food & Dining")
        assert food_cat["total_amount"] == 500.00
        assert food_cat["percentage"] == 62.50

        # Transport is 300 out of 800 -> 37.5%
        trans_cat = next(c for c in cats["expense_categories"] if c["category"] == "Transportation")
        assert trans_cat["total_amount"] == 300.00
        assert trans_cat["percentage"] == 37.50


class TestCategoriesAndDocs:
    def test_list_seeded_categories(self, client):
        res = client.get("/api/categories")
        assert res.status_code == 200
        data = res.json()
        assert len(data) >= 10
        names = [c["name"] for c in data]
        assert "Salary" in names
        assert "Food & Dining" in names

    def test_openapi_swagger_docs(self, client):
        docs_res = client.get("/docs")
        assert docs_res.status_code == 200
        openapi_res = client.get("/openapi.json")
        assert openapi_res.status_code == 200
        schema = openapi_res.json()
        assert "paths" in schema
        assert "/api/auth/register" in schema["paths"]
        assert "/api/transactions" in schema["paths"]
        assert "/api/analytics/summary" in schema["paths"]
