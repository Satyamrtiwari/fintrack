"""
FinTrack End-to-End Live Integration Verification Script
Tests complete API flows using FastAPI TestClient with persistent SQLite/PostgreSQL storage.
"""

import sys
import os

# Add backend directory to sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from fastapi.testclient import TestClient
from app.main import app

def run_e2e_verification():
    print("=" * 60)
    print("🚀 FINTRACK END-TO-END FULL-STACK API VERIFICATION")
    print("=" * 60)

    client = TestClient(app)

    # 1. Health & Docs Check
    print("\n[Step 1] Checking Health and OpenAPI Swagger Docs...")
    health_res = client.get("/health")
    assert health_res.status_code == 200, f"Health check failed: {health_res.text}"
    print("  ✓ Health check: OK")

    docs_res = client.get("/docs")
    assert docs_res.status_code == 200, f"Swagger docs check failed: {docs_res.text}"
    print("  ✓ Interactive Swagger documentation accessible at /docs: OK")

    # 2. User Registration
    print("\n[Step 2] User Registration (POST /api/auth/register)...")
    email = "david.finance@example.com"
    reg_res = client.post("/api/auth/register", json={
        "name": "David Sterling",
        "email": email,
        "password": "StrongPassword123!"
    })
    
    # If user already exists in persistent db from prior test, login instead
    if reg_res.status_code == 400 and "already exists" in reg_res.text:
        print(f"  ℹ User {email} already registered in DB, proceeding to login.")
        login_res = client.post("/api/auth/login", json={
            "email": email,
            "password": "StrongPassword123!"
        })
        assert login_res.status_code == 200, f"Login failed: {login_res.text}"
        auth_data = login_res.json()
    else:
        assert reg_res.status_code == 201, f"Registration failed: {reg_res.text}"
        auth_data = reg_res.json()
        print("  ✓ User registered successfully!")

    token = auth_data["access_token"]
    user_info = auth_data["user"]
    print(f"  ✓ JWT Token issued: {token[:20]}... (type: {auth_data['token_type']})")
    print(f"  ✓ User ID: {user_info['id']}, Name: {user_info['name']}, Email: {user_info['email']}")

    headers = {"Authorization": f"Bearer {token}"}

    # 3. Authenticated Profile
    print("\n[Step 3] Fetching Authenticated Profile (GET /api/auth/me)...")
    me_res = client.get("/api/auth/me", headers=headers)
    assert me_res.status_code == 200, f"Get me failed: {me_res.text}"
    print(f"  ✓ Verified profile: {me_res.json()['name']} ({me_res.json()['email']})")

    # 4. Fetch Categories
    print("\n[Step 4] Fetching Pre-seeded Categories (GET /api/categories)...")
    cat_res = client.get("/api/categories")
    assert cat_res.status_code == 200, f"Categories failed: {cat_res.text}"
    categories = cat_res.json()
    print(f"  ✓ Successfully retrieved {len(categories)} categories")
    print(f"    Sample categories: {[c['name'] for c in categories[:4]]}")

    # 5. Create Transactions (Income & Expenses)
    print("\n[Step 5] Creating Transactions (POST /api/transactions)...")
    
    # Income 1
    t1_res = client.post("/api/transactions", headers=headers, json={
        "title": "Software Consulting Salary",
        "amount": 6500.00,
        "type": "income",
        "category": "Salary",
        "transaction_date": "2026-11-01",
        "notes": "Direct bank transfer"
    })
    assert t1_res.status_code == 201, t1_res.text
    t1 = t1_res.json()
    print(f"  ✓ Created Income: ID {t1['id']} - {t1['title']}: +${t1['amount']}")

    # Income 2
    t2_res = client.post("/api/transactions", headers=headers, json={
        "title": "Stock Dividend",
        "amount": 350.00,
        "type": "income",
        "category": "Investments",
        "transaction_date": "2026-11-05",
        "notes": "Quarterly dividend"
    })
    assert t2_res.status_code == 201, t2_res.text
    t2 = t2_res.json()
    print(f"  ✓ Created Income: ID {t2['id']} - {t2['title']}: +${t2['amount']}")

    # Expense 1
    t3_res = client.post("/api/transactions", headers=headers, json={
        "title": "Apartment Rent",
        "amount": 1800.00,
        "type": "expense",
        "category": "Housing & Rent",
        "transaction_date": "2026-11-02",
        "notes": "Monthly rent payment"
    })
    assert t3_res.status_code == 201, t3_res.text
    t3 = t3_res.json()
    print(f"  ✓ Created Expense: ID {t3['id']} - {t3['title']}: -${t3['amount']}")

    # Expense 2
    t4_res = client.post("/api/transactions", headers=headers, json={
        "title": "Weekly Organic Groceries",
        "amount": 240.50,
        "type": "expense",
        "category": "Food & Dining",
        "transaction_date": "2026-11-08",
        "notes": "Whole Foods"
    })
    assert t4_res.status_code == 201, t4_res.text
    t4 = t4_res.json()
    print(f"  ✓ Created Expense: ID {t4['id']} - {t4['title']}: -${t4['amount']}")

    # 6. Reading Transactions
    print("\n[Step 6] Listing Transactions with Filtering (GET /api/transactions)...")
    list_res = client.get("/api/transactions?type=expense", headers=headers)
    assert list_res.status_code == 200, list_res.text
    expense_list = list_res.json()
    print(f"  ✓ Expense filter retrieved {len(expense_list['transactions'])} transactions")

    # 7. Updating a Transaction
    print("\n[Step 7] Updating a Transaction (PUT /api/transactions/{id})...")
    update_res = client.put(f"/api/transactions/{t4['id']}", headers=headers, json={
        "title": "Weekly Organic Groceries & Household Essentials",
        "amount": 265.00
    })
    assert update_res.status_code == 200, update_res.text
    updated_t4 = update_res.json()
    assert updated_t4["amount"] == 265.00
    print(f"  ✓ Updated amount to ${updated_t4['amount']} and title to '{updated_t4['title']}'")

    # 8. Financial Analytics Summary
    print("\n[Step 8] Calculating Analytics Summary (GET /api/analytics/summary)...")
    summary_res = client.get("/api/analytics/summary", headers=headers)
    assert summary_res.status_code == 200, summary_res.text
    summary = summary_res.json()
    print(f"  ✓ Total Income:     ${summary['total_income']:,.2f}")
    print(f"  ✓ Total Expenses:   ${summary['total_expenses']:,.2f}")
    print(f"  ✓ Net Savings:      ${summary['net_savings']:,.2f}")
    print(f"  ✓ Savings Rate:     {summary['savings_rate']}%")
    print(f"  ✓ Total Count:      {summary['transaction_count']}")

    # 9. Monthly Cashflow Breakdown
    print("\n[Step 9] Calculating Monthly Cashflow (GET /api/analytics/monthly)...")
    monthly_res = client.get("/api/analytics/monthly?months=6", headers=headers)
    assert monthly_res.status_code == 200, monthly_res.text
    monthly_data = monthly_res.json()["monthly_data"]
    print(f"  ✓ Retrieved {len(monthly_data)} monthly trend periods")
    latest = monthly_data[-1]
    print(f"    Latest Period ({latest['month']}): Income=${latest['income']}, Expense=${latest['expense']}, Net=${latest['net']}")

    # 10. Category Breakdown
    print("\n[Step 10] Calculating Category Distribution (GET /api/analytics/categories)...")
    cat_analytics_res = client.get("/api/analytics/categories", headers=headers)
    assert cat_analytics_res.status_code == 200, cat_analytics_res.text
    cat_analytics = cat_analytics_res.json()
    print(f"  ✓ Expense Categories Count: {len(cat_analytics['expense_categories'])}")
    for ec in cat_analytics["expense_categories"]:
        print(f"    - {ec['category']}: ${ec['total_amount']} ({ec['percentage']}%)")

    # 11. Deleting a Transaction
    print("\n[Step 11] Deleting a Transaction (DELETE /api/transactions/{id})...")
    del_res = client.delete(f"/api/transactions/{t2['id']}", headers=headers)
    assert del_res.status_code == 200, del_res.text
    print(f"  ✓ Deleted transaction ID {t2['id']}")

    # Verify 404 after deletion
    verify_del = client.get(f"/api/transactions/{t2['id']}", headers=headers)
    assert verify_del.status_code == 404
    print("  ✓ Verified deleted transaction returns HTTP 404")

    # 12. Security & Isolation Check
    print("\n[Step 12] Security & Multi-User Isolation Checks...")
    
    # Unauthorized without header
    unauth_res = client.get("/api/transactions")
    assert unauth_res.status_code in (401, 403), f"Expected 401/403, got {unauth_res.status_code}"
    print("  ✓ Protected endpoint rejected unauthenticated request: OK")

    # Another user cannot access David's transaction
    reg_eve = client.post("/api/auth/register", json={
        "name": "Eve Sneak",
        "email": "eve.sneak@example.com",
        "password": "EvePassword999!"
    })
    if reg_eve.status_code == 400:
        login_eve = client.post("/api/auth/login", json={
            "email": "eve.sneak@example.com",
            "password": "EvePassword999!"
        })
        eve_token = login_eve.json()["access_token"]
    else:
        eve_token = reg_eve.json()["access_token"]
    
    eve_headers = {"Authorization": f"Bearer {eve_token}"}
    eve_probe = client.get(f"/api/transactions/{t1['id']}", headers=eve_headers)
    assert eve_probe.status_code == 404, f"Data leak detected! Eve was able to access David's tx: {eve_probe.text}"
    print("  ✓ Cross-user isolation verified: User B cannot access User A's transaction (HTTP 404)")

    print("\n" + "=" * 60)
    print("✨ ALL END-TO-END FLOWS AND CHECKS PASSED WITH 100% SUCCESS!")
    print("=" * 60)

if __name__ == "__main__":
    run_e2e_verification()
