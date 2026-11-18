# FinTrack – Full-Stack Personal Finance Application

FinTrack is an enterprise-grade, full-stack personal finance management application engineered with a **Flutter (Dart)** frontend and a **Python (FastAPI)** backend. The system provides real-time income and expense tracking, categorical budgeting, JWT-authenticated security with strict multi-user tenant isolation, monthly cashflow analytics with interactive charts (`fl_chart`), and reactive state synchronization using **Riverpod** and **GoRouter**.

---

## 1. Architecture Overview

FinTrack follows a clean, decoupled client-server architecture:

```
┌────────────────────────────────────────────────────────┐
│                   Flutter Frontend                     │
│  (Riverpod State Management + GoRouter + fl_chart)     │
└───────────────────────────┬────────────────────────────┘
                            │ REST API (JSON / HTTP)
                            │ Authorization: Bearer <JWT>
┌───────────────────────────▼────────────────────────────┐
│                  Python FastAPI Backend                │
│  - Routers: Auth, Transactions, Analytics, Categories  │
│  - Dependencies: JWT Bearer Token, Current User Guard  │
│  - Services: Business Logic, Aggregations, Math        │
│  - Pydantic v2: Request / Response Validation          │
└───────────────────────────┬────────────────────────────┘
                            │ SQLAlchemy 2.0 ORM
┌───────────────────────────▼────────────────────────────┐
│                  PostgreSQL / SQLite                   │
│  - Users (Credentials, Passwords Hashed with Bcrypt)   │
│  - Transactions (Income/Expense, User FK, Cascades)    │
│  - Categories (Visual Themes, Icons, Types)            │
└────────────────────────────────────────────────────────┘
```

---

## 2. Technology Stack

### Frontend
- **Framework**: Flutter 3 (Dart)
- **State Management**: `flutter_riverpod` (v2.5) – manages API caching, filter state, and cross-provider cache invalidation upon CRUD operations.
- **Routing**: `go_router` (v14) – declarative routing with authentication guards (`RouterNotifier`).
- **Charts & Data Visualization**: `fl_chart` (v0.68) – interactive monthly cashflow bar charts and category distribution donut/pie charts.
- **HTTP Client**: `http` (v1.2) – custom `ApiClient` service layer handling base URL resolution, bearer token attachment, automatic 401 session expiration, and error parsing.
- **Local Persistence**: `shared_preferences` – securely caches auth tokens, active user profile, custom API host configuration, and UI theme preferences.
- **Formatting**: `intl` – currency formatting and localized date handling.

### Backend
- **Framework**: Python 3.13 / FastAPI (v0.115) – high-performance asynchronous REST API.
- **ORM & Data Layer**: SQLAlchemy (v2.0) – relational mappings, foreign key cascading, and database abstraction.
- **Database**: PostgreSQL (production) with automatic SQLite fallback for local development.
- **Validation**: Pydantic v2 – strict schema validation for all incoming and outgoing payloads.
- **Authentication**: OAuth2 Password Flow & JWT (`python-jose`) with expiration and cryptographic signature.
- **Password Hashing**: `passlib` with `bcrypt` algorithm.
- **Documentation**: Automatic OpenAPI 3.0 interactive Swagger docs at `/docs` and ReDoc at `/redoc`.

---

## 3. Database Schema

The database consists of three relational models:

```
  ┌─────────────────────────┐           ┌─────────────────────────┐
  │         users           │           │       categories        │
  ├─────────────────────────┤           ├─────────────────────────┤
  │ PK id (Integer)         │           │ PK id (Integer)         │
  │    name (String)        │           │    name (String, Unique)│
  │    email (String, Unique│           │    type (String)        │
  │    hashed_password (Str)│           │    icon (String)        │
  │    created_at (DateTime)│           │    color (String)       │
  └────────────┬────────────┘           └─────────────────────────┘
               │ 1
               │
               │ N (CASCADE)
  ┌────────────▼────────────┐
  │      transactions       │
  ├─────────────────────────┤
  │ PK id (Integer)         │
  │ FK user_id (Integer)    │
  │    title (String)       │
  │    amount (Float)       │
  │    type (String)        │
  │    category (String)    │
  │    transaction_date     │
  │    notes (Text, Nullable│
  │    created_at (DateTime)│
  └─────────────────────────┘
```

### Key Integrity & Security Rules:
1. **User Isolation**: Every transaction row has an indexed `user_id` foreign key. Endpoints strictly enforce `Transaction.user_id == current_user.id` on all `GET`, `PUT`, and `DELETE` queries.
2. **Cascading Deletes**: If a user account is deleted, all associated transactions are automatically purged (`ondelete="CASCADE"`).
3. **Data Integrity**: Amounts are strictly positive (`gt=0`), transaction types are restricted to `'income'` or `'expense'`, and transaction dates are validated against standard ISO date formats.

---

## 4. API Endpoints

The backend provides full Swagger UI documentation at **`http://localhost:8000/docs`**.

### Authentication (`/api/auth`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `POST` | `/api/auth/register` | Register a new user with name, email, password | No |
| `POST` | `/api/auth/login` | Authenticate with email and password, receive JWT | No |
| `GET` | `/api/auth/me` | Fetch authenticated user profile | Yes (Bearer) |

### Transactions (`/api/transactions`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/transactions` | List transactions with filtering (`type`, `category`, `start_date`, `end_date`, `search`) and pagination (`limit`, `offset`) | Yes (Bearer) |
| `POST` | `/api/transactions` | Record a new income or expense transaction | Yes (Bearer) |
| `GET` | `/api/transactions/{id}` | Retrieve details of a specific transaction | Yes (Bearer) |
| `PUT` | `/api/transactions/{id}` | Update an existing transaction | Yes (Bearer) |
| `DELETE` | `/api/transactions/{id}` | Delete a transaction | Yes (Bearer) |

### Analytics (`/api/analytics`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/analytics/summary` | Overall totals (Total Income, Expenses, Net Savings, Savings Rate %, Transaction Count) | Yes (Bearer) |
| `GET` | `/api/analytics/monthly` | Cashflow trends grouped by month for the past X months | Yes (Bearer) |
| `GET` | `/api/analytics/categories` | Categorical expenditure and income distribution with percentage breakdowns | Yes (Bearer) |

### Categories (`/api/categories`)
| Method | Endpoint | Description | Auth Required |
|---|---|---|---|
| `GET` | `/api/categories` | List pre-seeded and custom categories with visual icons & colors | No |
| `POST` | `/api/categories` | Add a custom category | Yes (Bearer) |

---

## 5. Project Directory Structure

```
fintrack/
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── config.py           # Pydantic environment configuration & settings
│   │   ├── database.py         # SQLAlchemy engine, session maker, get_db()
│   │   ├── dependencies.py     # JWT Bearer token authentication & current user dependency
│   │   ├── main.py             # FastAPI entrypoint, CORS, lifecycle hooks, and seed data
│   │   ├── models/             # SQLAlchemy ORM models (User, Transaction, Category)
│   │   │   ├── __init__.py
│   │   │   ├── category.py
│   │   │   ├── transaction.py
│   │   │   └── user.py
│   │   ├── routers/            # FastAPI route handlers
│   │   │   ├── __init__.py
│   │   │   ├── analytics.py
│   │   │   ├── auth.py
│   │   │   ├── categories.py
│   │   │   └── transactions.py
│   │   ├── schemas/            # Pydantic models for request/response serialization
│   │   │   ├── __init__.py
│   │   │   ├── analytics.py
│   │   │   ├── category.py
│   │   │   ├── transaction.py
│   │   │   └── user.py
│   │   └── services/           # Core business logic & database querying
│   │       ├── __init__.py
│   │       ├── analytics_service.py
│   │       ├── auth_service.py
│   │       └── transaction_service.py
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_api.py         # Comprehensive pytest suite (15 automated unit & integration tests)
│   ├── verify_live_flow.py     # End-to-end integration test executing all user flows
│   ├── requirements.txt        # Backend dependencies
│   ├── .env                    # Active local environment variables
│   └── .env.example            # Template for environment configuration
│
├── frontend/
│   ├── android/                # Android platform native configuration
│   │   ├── app/
│   │   │   ├── build.gradle    # Android Gradle config with Java 17 & SDK 34
│   │   │   └── src/main/AndroidManifest.xml # Internet & network permissions
│   │   ├── build.gradle
│   │   └── settings.gradle
│   ├── lib/
│   │   ├── core/
│   │   │   ├── constants/      # API endpoints, colors, light/dark themes
│   │   │   ├── network/        # ApiClient HTTP wrapper with token management & error handling
│   │   │   ├── storage/        # SharedPreferences service for tokens & settings
│   │   │   └── utils/          # Currency and date formatters
│   │   ├── features/
│   │   │   ├── analytics/      # Monthly bar chart & category donut chart screen
│   │   │   ├── auth/           # Login and Registration forms with validation
│   │   │   ├── dashboard/      # Net balance, income/expense cards, recent transactions
│   │   │   ├── profile/        # User profile, statistics, logout modal
│   │   │   ├── settings/       # Server base URL config, currency switcher, dark mode toggle
│   │   │   └── transactions/   # Transaction list with search/filters & Add/Edit form
│   │   ├── models/             # Dart data models with JSON serialization
│   │   ├── providers/          # Riverpod StateNotifier providers & cross-invalidation logic
│   │   ├── routing/            # GoRouter with authentication route guards
│   │   ├── services/           # Frontend API client service modules
│   │   ├── widgets/            # Reusable UI widgets (cards, buttons, inputs, tiles)
│   │   └── main.dart           # App entrypoint with ProviderScope & SharedPreferences init
│   └── pubspec.yaml            # Flutter dependencies and project metadata
│
└── README.md                   # Complete architectural and setup documentation
```

---

## 6. How to Run the Backend

### Prerequisites
- Python 3.10+ (tested on Python 3.13)
- (Optional) PostgreSQL installed and running locally

### Step 1: Install Dependencies
Open a terminal in `fintrack/backend`:
```powershell
cd "fintrack/backend"
python -m pip install -r requirements.txt
```

### Step 2: Configure Environment Variables
Copy `.env.example` to `.env`:
```powershell
cp .env.example .env
```
For PostgreSQL, set:
```ini
DATABASE_URL=postgresql+psycopg2://postgres:your_password@localhost:5432/fintrack
```
For SQLite (zero-configuration development):
```ini
DATABASE_URL=sqlite:///./fintrack.db
```

### Step 3: Run the FastAPI Server
```powershell
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```
- Interactive Swagger documentation: **`http://localhost:8000/docs`**
- ReDoc documentation: **`http://localhost:8000/redoc`**

---

## 7. How to Run Backend Tests

FinTrack includes a comprehensive automated test suite testing user authentication, password hashing, CRUD operations, analytics, multi-user tenant isolation, and error handling.

Run pytest:
```powershell
cd "fintrack/backend"
$env:PYTHONPATH="."
python -m pytest tests -v
```

Run the End-to-End Live Integration Verification script:
```powershell
python verify_live_flow.py
```

---

## 8. How to Run the Flutter Frontend

### Prerequisites
- Flutter SDK 3.19+ (with Dart 3.0+)
- Android Studio / Android Emulator or Chrome for Flutter Web

### Step 1: Install Flutter Packages
Open a terminal in `fintrack/frontend`:
```powershell
cd "fintrack/frontend"
flutter pub get
```

### Step 2: Configure Backend Connection
The app connects to the FastAPI backend dynamically:
- **Android Emulator**: Uses `http://10.0.2.2:8000` automatically.
- **Flutter Web / Desktop**: Uses `http://localhost:8000` automatically.
- **Physical Mobile Device on Wi-Fi**: Open the in-app **Settings** screen (or click "Configure Server" on the login page) and enter your development computer's local IP (e.g. `http://192.168.1.50:8000`).

### Step 3: Launch the Application
To run in Chrome (Flutter Web):
```powershell
flutter run -d chrome
```

To run on an Android device or emulator:
```powershell
flutter run -d android
```

---

## 9. Building the Android Release APK (Stage 9)

The Android configuration has been pre-configured in `fintrack/frontend/android/`:
- **Permissions**: `android.permission.INTERNET` and `android.permission.ACCESS_NETWORK_STATE` are enabled in `AndroidManifest.xml`.
- **Cleartext Traffic**: `android:usesCleartextTraffic="true"` is enabled to allow smooth HTTP communication with local API servers during development and staging.
- **Gradle & Java**: Configured for modern Gradle with Java 17 and `compileSdkVersion 34`.

To generate the standalone release APK:
```powershell
cd "fintrack/frontend"
flutter build apk --release
```

The compiled APK will be generated at:
```
fintrack/frontend/build/app/outputs/flutter-apk/app-release.apk
```

To install directly to a connected Android phone or emulator:
```powershell
flutter install
```

---

## 10. Security Architecture

1. **Password Hashing**: Passwords are never stored in plaintext. They are salted and hashed using standard `bcrypt` before database insertion.
2. **JWT Authentication**: Authenticated sessions issue signed JSON Web Tokens using standard HMAC-SHA256 (`HS256`).
3. **Endpoint Protection**: Private endpoints depend on `get_current_user` (`HTTPBearer`). If an invalid, expired, or missing token is provided, the API returns HTTP 401 Unauthorized.
4. **Tenant Isolation**: All transaction queries (`SELECT`, `UPDATE`, `DELETE`) include `filter(Transaction.user_id == current_user.id)`. Any attempt by User A to access, modify, or delete a transaction owned by User B returns HTTP 404 Not Found, preventing ID enumeration.
5. **Validation**: Pydantic models validate all inputs (email format, positive non-zero amounts, valid categories, dates, and password length).
