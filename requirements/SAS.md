# Software Architecture Specification (SAS)

**Project:** saveMoney
**Version:** 1.0
**Last Updated:** 2026-04-02

---

## 1. Architecture Overview (Tổng quan kiến trúc)

**Pattern:** Layered Architecture (4 tầng)

```
┌─────────────────────────────────┐
│  Presentation Layer (React SPA) │  ← User Interface
├─────────────────────────────────┤
│  API Layer (Express REST)       │  ← HTTP endpoints
├─────────────────────────────────┤
│  Business Logic (Utils/Service) │  ← Analytics, Gold pricing
├─────────────────────────────────┤
│  Data Layer (MySQL)             │  ← Persistence
└─────────────────────────────────┘
         │ External
┌─────────────────────────────────┐
│  External APIs (Gold / FX)      │  ← SJC, BTMC, fxratesapi, Yahoo
└─────────────────────────────────┘
```

**Tech Stack:**

| Layer | Technology | Version |
|-------|-----------|---------|
| Frontend framework | React | 19.0.0 |
| Language | TypeScript | ~5.8.2 |
| Build tool | Vite | 6.2.0 |
| CSS | Tailwind CSS | 4.1.14 |
| Charts | Recharts | 3.8.0 |
| Icons | Lucide React | 0.546.0 |
| Animations | Motion | 12.23.24 |
| Backend | Express | 4.21.2 |
| DB driver | mysql2 | 3.20.0 |
| Database | MySQL | 8.x |
| Runtime | Node.js + tsx | LTS |
| AI (optional) | Google Gemini API | @google/genai 1.29.0 |

---

## 2. Component Diagram (Sơ đồ thành phần)

```
Browser (localhost:3000)
│
└── React SPA (Vite dev server)
    │
    ├── AppContext (useReducer + React Context)
    │   ├── State: transactions, categories, accounts, budgets,
    │   │         goldAssets, filters, selectedPeriod, settings
    │   └── Actions: ADD/UPDATE/DELETE cho từng entity + SET_FILTERS
    │
    ├── Router (React Router DOM 7)
    │   ├── / ──────────── Dashboard
    │   ├── /transactions ─ Transactions
    │   ├── /analytics ─── Analytics
    │   ├── /budget ─────── Budget
    │   ├── /gold ────────── Gold Price
    │   ├── /wealth ──────── Wealth Management
    │   ├── /accounts ─────── Account Management
    │   ├── /categories ───── Category Management
    │   └── /settings ──────── Settings & Data
    │
    ├── Layout Components
    │   ├── Layout.tsx ─── Main wrapper
    │   ├── Sidebar.tsx ── Navigation
    │   └── Header.tsx ─── Page header
    │
    ├── Shared Components
    │   ├── AddTransactionModal.tsx
    │   ├── InlineEditForm.tsx
    │   ├── InlineFields.tsx
    │   ├── Combobox.tsx
    │   ├── MiniCalendar.tsx
    │   └── GoldPriceChart.tsx
    │
    ├── Utility Modules (src/utils/)
    │   ├── analytics.ts ─── Calculation functions
    │   ├── csvParser.ts ─── CSV import/export
    │   ├── backup.ts ────── JSON backup/restore
    │   ├── formatters.ts ── Number & date formatting
    │   ├── goldParser.ts ── Parse SJC/BTMC HTML/JSON
    │   ├── lookup.ts ─────── ID → Name resolution
    │   └── migration.ts ─── v1 → v2 backup migration
    │
    └── Services (src/services/)
        ├── api.ts ──────────── HTTP client to backend
        ├── goldPriceService.ts ─ Fetch + cache gold prices
        └── goldHistoryService.ts ─ Daily snapshots to localStorage
                    │
                    │ HTTP REST (localhost:3001/api)
                    ▼
Express Server (port 3001)
│
├── /api/init ─────────── GET: load all data on startup
├── /api/transactions ─── GET/POST/PUT/DELETE
├── /api/transactions/bulk ─ POST: bulk import
├── /api/categories ──────── GET/POST/DELETE
├── /api/accounts ──────────── GET/POST/PUT/DELETE
├── /api/budgets ───────────── GET/POST/PUT/DELETE
├── /api/gold-assets ────────── GET/POST/PUT/DELETE
└── /api/settings ────────────── GET/POST
            │
            ▼
    MySQL (savemoney_db) — port 3306
            │
External APIs (via Vite proxy)
    ├── /api/sjc/* ──── SJC gold price JSON
    ├── /api/btmc/* ─── BTMC gold price HTML
    ├── /api/gold-futures/* ─ Yahoo Finance GC=F
    └── /api/fx/* ────────── fxratesapi.com USD/VND
```

---

## 3. Component Descriptions (Mô tả thành phần)

### AppContext (`src/context/AppContext.tsx`)
- **Responsibility:** Quản lý toàn bộ application state bằng `useReducer`. Single source of truth cho mọi data.
- **Interfaces:** React Context API — `useApp()` hook
- **Dependencies:** `src/services/api.ts`, `src/types/index.ts`
- **State:** transactions, categories, accounts, accountBalances, budgets, goldAssets, filters, selectedPeriod, defaultSettings, isLoading
- **Actions:** ADD/UPDATE/DELETE_TRANSACTION, ADD/DELETE_CATEGORY, ADD/UPDATE/DELETE_ACCOUNT, ADD/UPDATE/DELETE_BUDGET, ADD/UPDATE/DELETE_GOLD_ASSET, SET_FILTERS, SET_PERIOD, SET_DEFAULTS

### API Service (`src/services/api.ts`)
- **Responsibility:** HTTP client — wrap toàn bộ calls tới Express backend
- **Interfaces:** Exported async functions per entity
- **Dependencies:** `fetch()`, base URL `http://localhost:3001`

### Analytics Engine (`src/utils/analytics.ts`)
- **Responsibility:** Tính toán tất cả metrics từ raw transaction data
- **Key functions:**
  - `getExpenses(transactions, period)` — filter expenses theo period
  - `getTotalSpending()`, `getTotalIncome()` — aggregate totals
  - `getCategoryBreakdown()` — chi tiêu nhóm theo category
  - `getCategoryMonthMatrix()` — matrix category × tháng
  - `getMonthlyComparison()` — so sánh tháng
  - `getAccountNetTotals()` — net flow per account
- **Dependencies:** `src/types/index.ts`, `src/utils/formatters.ts`

### Gold Price Service (`src/services/goldPriceService.ts`)
- **Responsibility:** Fetch và cache giá vàng từ 3 nguồn
- **Cache:** localStorage key `savemoney_gold_cache`, TTL 5 phút
- **Sources:**
  - SJC: `/api/sjc/GoldPrice/Services/PriceService.ashx`
  - BTMC: `/api/btmc/gia-vang-theo-ngay.html`
  - World spot: `https://api.fxratesapi.com/latest?base=XAU&currencies=USD`
  - World futures: `/api/gold-futures/v8/finance/chart/GC=F`
  - USD/VND: `/api/fx/v6/latest/USD`
- **Fallback:** USD/VND = 25,400 nếu API lỗi

### Gold History Service (`src/services/goldHistoryService.ts`)
- **Responsibility:** Lưu daily snapshots giá vàng vào localStorage để vẽ biểu đồ lịch sử
- **Storage:** localStorage key `savemoney_gold_history`
- **Rule:** 1 snapshot / ngày (BR-17)

### Express Routes (`server/routes/`)
- **Responsibility:** REST API endpoints, SQL queries, response formatting
- **Pattern:** Router per entity — accounts.ts, budgets.ts, categories.ts, goldAssets.ts, init.ts, settings.ts, transactions.ts

---

## 4. Data Flow (Luồng dữ liệu)

### 4.1 — Khởi động ứng dụng

```
Browser load
    → AppContext.init()
    → GET /api/init
    → MySQL: SELECT categories, accounts, transactions, budgets, gold_assets, settings
    → AppContext dispatch SET_INIT_DATA
    → React re-render toàn bộ UI
```

### 4.2 — Thêm giao dịch mới

```
User submit form (AddTransactionModal)
    → AppContext dispatch ADD_TRANSACTION (optimistic)
    → POST /api/transactions {date, type, categoryId, accountId, amount, note}
    → MySQL: INSERT INTO transactions
    → Response: {id, ...}
    → AppContext confirm với server ID
```

### 4.3 — Fetch giá vàng

```
User mở trang Gold
    → goldPriceService.fetchGoldPrices()
    → Check localStorage cache (savemoney_gold_cache)
    → Cache valid (< 5 phút)?
        YES: return cache
        NO:  Parallel fetch SJC + BTMC + World (Promise.allSettled)
            → Parse responses (goldParser.ts)
            → Save to localStorage cache
            → goldHistoryService.maybeRecordTodaySnapshot()
            → return merged GoldPriceCache
    → UI render prices
```

### 4.4 — Import CSV

```
User drop file CSV
    → csvParser.ts parse raw text
    → Preview transactions table
    → User confirm
    → POST /api/transactions/bulk [{...}, ...]
    → MySQL: INSERT IGNORE INTO transactions
    → AppContext reload transactions
```

### 4.5 — Backup / Restore

```
Export:
    → backup.ts.exportBackup()
    → Collect: transactions, categories, accounts, accountBalances, budgets (goldAssets optional)
    → JSON.stringify version 2 format
    → Download file savemoney-backup-YYYY-MM-DD.json

Restore:
    → backup.ts.importBackup(file)
    → migration.ts: v1 → v2 nếu cần
    → POST /api/settings/restore (or per-entity bulk endpoints)
    → AppContext reload
```

---

## 5. Database Schema (Sơ đồ cơ sở dữ liệu)

**Database:** `savemoney_db` (MySQL 8.x)

### transactions
```sql
CREATE TABLE transactions (
  id            VARCHAR(36)  PRIMARY KEY,
  date          DATE         NOT NULL,
  type          VARCHAR(20)  NOT NULL,      -- 'Expense'|'Income'|'Account'|'Transfer'
  category_id   VARCHAR(36)  NULL,
  account_id    VARCHAR(36)  NOT NULL,
  transfer_to_id VARCHAR(36) NULL,
  amount        BIGINT       NOT NULL,      -- signed VND, negative = expense
  note          TEXT         NULL
);
```

### categories
```sql
CREATE TABLE categories (
  id    VARCHAR(36)  PRIMARY KEY,
  name  VARCHAR(255) NOT NULL,
  type  VARCHAR(20)  NOT NULL  -- 'Expense'|'Income'
);
```

### accounts
```sql
CREATE TABLE accounts (
  id    VARCHAR(36)  PRIMARY KEY,
  name  VARCHAR(255) NOT NULL
);
```

### account_balances
```sql
CREATE TABLE account_balances (
  account_id  VARCHAR(36)  PRIMARY KEY,
  balance     BIGINT       NOT NULL DEFAULT 0  -- initial balance VND
);
```

### budgets
```sql
CREATE TABLE budgets (
  id            VARCHAR(36)   PRIMARY KEY,
  name          VARCHAR(255)  NOT NULL,
  limit_amount  BIGINT        NOT NULL,   -- VND
  date_start    DATE          NOT NULL,
  date_end      DATE          NOT NULL
);
```

### budget_categories
```sql
CREATE TABLE budget_categories (
  budget_id    VARCHAR(36) NOT NULL,
  category_id  VARCHAR(36) NOT NULL,
  PRIMARY KEY (budget_id, category_id)
);
```

### gold_assets
```sql
CREATE TABLE gold_assets (
  id           VARCHAR(36)   PRIMARY KEY,
  brand        VARCHAR(20)   NOT NULL,      -- 'SJC'|'BTMC'|'world'
  product_id   VARCHAR(100)  NULL,
  product_name VARCHAR(255)  NOT NULL,
  quantity     DECIMAL(10,4) NOT NULL,      -- in lượng
  note         TEXT          NULL,
  created_at   VARCHAR(50)   NOT NULL       -- ISO timestamp
);
```

### user_settings
```sql
CREATE TABLE user_settings (
  `key`   VARCHAR(100) PRIMARY KEY,
  value   TEXT         NOT NULL
  -- keys: defaultCategoryExpenseId, defaultCategoryIncomeId, defaultAccountId
);
```

### Gold Price Storage (localStorage — không phải MySQL)

| Key | Structure | TTL |
|-----|-----------|-----|
| `savemoney_gold_cache` | `GoldPriceCache` JSON | 5 phút |
| `savemoney_gold_history` | `GoldPriceHistory` JSON | Persistent (daily snapshots) |

---

## 6. Integration Points (Điểm tích hợp)

| Integration | Protocol | Direction | Description |
|-------------|----------|-----------|-------------|
| SJC Gold Price | HTTPS → Vite proxy `/api/sjc/*` | Outbound | Giá vàng SJC (JSON format) |
| BTMC Gold Price | HTTPS → Vite proxy `/api/btmc/*` | Outbound | Giá vàng BTMC (HTML scraping) |
| fxratesapi.com | HTTPS direct | Outbound | XAUUSD spot price (no key required) |
| Yahoo Finance | HTTPS → Vite proxy `/api/gold-futures/*` | Outbound | GC=F futures price |
| fxratesapi USD/VND | HTTPS → Vite proxy `/api/fx/*` | Outbound | Tỷ giá USD/VND |
| Google Gemini AI | HTTPS | Outbound | Optional AI feature (key via env var) |
| Savey iOS App | File import (CSV) | Inbound | Transaction data export |

**Vite Proxy config:** Tất cả `/api/sjc`, `/api/btmc`, `/api/gold-futures`, `/api/fx` được proxy qua Vite để tránh CORS. `/api/*` còn lại proxy tới Express localhost:3001.

---

## 7. Key Design Decisions (Quyết định thiết kế quan trọng)

| Decision | Rationale | Alternatives Considered |
|----------|-----------|------------------------|
| useReducer + Context (không dùng Redux/Zustand) | App single-user, state không quá phức tạp — tránh over-engineering | Redux Toolkit, Zustand |
| MySQL thay vì localStorage/IndexedDB | Dữ liệu lớn (10k+ transactions), cần query phức tạp và persist lâu dài | localStorage, IndexedDB, SQLite |
| Gold price cache ở localStorage (không phải DB) | Giá vàng là transient data, không cần sync với server, user-specific | MySQL cache table |
| Vite proxy cho gold APIs | CORS restriction — không thể call trực tiếp từ browser | Backend proxy endpoint |
| Signed amount (âm/dương) thay vì 2 field | Đơn giản hóa tính toán aggregate (sum is all) | separate income/expense fields |
| Gold unit = lượng (không phải gram hay troy oz) | Thị trường vàng VN dùng đơn vị lượng; SJC/BTMC quote theo lượng | gram, troy oz |
| UUIDs cho entity IDs | Tương thích với Savey iOS export format; collision-free | auto-increment INT |
| Backup format version 2 | Refactor từ v1 (category/account by name) sang v2 (by ID) để hỗ trợ rename | v1 only |

---

## 8. Change History

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-04-02 | 1.0 | Initial SAS — reverse-engineered từ codebase | Claude |
