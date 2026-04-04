# SaveMoney Mobile App — API Reference

## Cấu hình chung

| Thuộc tính | Giá trị |
|-----------|---------|
| Base URL | Cấu hình trong Settings, mặc định `http://localhost:3001` |
| Content-Type | `application/json` |
| Timeout | 30 giây |
| Success codes | 200–299 |
| Error handling | HTTP status ≥ 400 → throw error với message từ response body |

---

## Init

### GET /api/init

Tải toàn bộ dữ liệu ban đầu của app.

**Request:** Không có body

**Response:**
```json
{
  "transactions": [Transaction],
  "categories": [Category],
  "accounts": [Account],
  "accountBalances": { "accountId": 1000000.0 },
  "budgets": [Budget],
  "goldAssets": [GoldAsset],
  "settings": {
    "default_transaction_type": "Expense",
    "default_account_id": "uuid",
    "default_expense_category_id": "uuid",
    "default_income_category_id": "uuid"
  }
}
```

**Gọi khi:** App khởi động, người dùng nhấn Refresh.

---

## Transactions

### GET /api/transactions

Lấy danh sách tất cả giao dịch.

**Response:** `[Transaction]`

---

### POST /api/transactions

Tạo giao dịch mới.

**Request body:**
```json
{
  "date": "2024-01-15",
  "type": "Expense",
  "categoryId": "uuid",
  "accountId": "uuid",
  "transferToId": null,
  "amount": -150000,
  "note": "Cà phê sáng"
}
```

**Response:** `Transaction` (object vừa tạo)

---

### PUT /api/transactions/{id}

Cập nhật giao dịch.

**Request body:** Giống POST, tất cả các field.

**Response:** Không yêu cầu body cụ thể (2xx = thành công)

---

### DELETE /api/transactions/{id}

Xóa giao dịch.

**Response:** Không có body (2xx = thành công)

---

## Accounts

### GET /api/accounts

Lấy danh sách tài khoản.

**Response:** `[Account]`

---

### POST /api/accounts

Tạo tài khoản mới.

**Request body:**
```json
{
  "name": "Tiền mặt",
  "balance": 5000000
}
```

**Response:** `Account` (object vừa tạo)

---

### PUT /api/accounts/{id}

Cập nhật tài khoản.

**Request body:**
```json
{
  "name": "Tiền mặt",
  "balance": 6000000
}
```

**Response:** `Account` (object đã cập nhật)

---

### DELETE /api/accounts/{id}

Xóa tài khoản.

**Response:** Không có body (2xx = thành công)

---

## Categories

### GET /api/categories

Lấy danh sách categories.

**Response:** `[Category]`

---

### POST /api/categories

Tạo category mới.

**Request body:**
```json
{
  "name": "Ăn uống",
  "type": "expense"
}
```

**Response:** `Category` (object vừa tạo)

---

### PUT /api/categories/{id}

Cập nhật tên category.

**Request body:**
```json
{
  "name": "Tên mới"
}
```

**Response:**
```json
{ "ok": true }
```

---

### DELETE /api/categories/{id}

Xóa category.

**Response:** Không có body (2xx = thành công)

---

## Budgets

### GET /api/budgets

Lấy danh sách ngân sách.

**Response:** `[Budget]`

---

### POST /api/budgets

Tạo ngân sách mới.

**Request body:**
```json
{
  "name": "Chi tiêu tháng 1",
  "limitAmount": 5000000,
  "dateStart": "2024-01-01",
  "dateEnd": "2024-01-31",
  "categoryIds": ["uuid1", "uuid2"]
}
```

**Response:** `Budget` (object vừa tạo)

---

### DELETE /api/budgets/{id}

Xóa ngân sách.

**Response:** Không có body (2xx = thành công)

---

## Gold Prices

### GET /api/gold-prices

Lấy giá vàng hiện tại.

**Response:**
```json
{
  "items": [
    {
      "id": "sjc-1luong",
      "name": "SJC 1 Lượng",
      "buyPrice": 82000000,
      "sellPrice": 84000000,
      "brand": "sjc"
    }
  ],
  "usdVnd": 25400,
  "fetchedAt": "2024-01-15T10:30:00Z"
}
```

**Gọi khi:** Cache rỗng hoặc cache đã quá 5 phút, hoặc người dùng nhấn Refresh.

---

## Gold Assets

### GET /api/gold-assets

Lấy danh sách tài sản vàng.

**Response:** `[GoldAsset]`

---

### POST /api/gold-assets

Thêm tài sản vàng.

**Request body:**
```json
{
  "brand": "sjc",
  "productId": "sjc-1luong",
  "productName": "SJC 1 Lượng",
  "quantity": 2.5,
  "note": "Mua ngày 15/1"
}
```

**Response:** `GoldAsset` (object vừa tạo)

---

### DELETE /api/gold-assets/{id}

Xóa tài sản vàng.

**Response:** Không có body (2xx = thành công)

---

## Settings

### GET /api/settings

Lấy toàn bộ settings.

**Response:**
```json
{
  "default_transaction_type": "Expense",
  "default_account_id": "uuid",
  "default_expense_category_id": "uuid",
  "default_income_category_id": "uuid"
}
```

---

### PUT /api/settings

Cập nhật một hoặc nhiều settings.

**Request body:** Object key-value bất kỳ
```json
{
  "default_transaction_type": "Income",
  "default_account_id": "uuid-new"
}
```

**Response:**
```json
{ "ok": true }
```

---

## Tóm tắt endpoints

| Endpoint | GET | POST | PUT | DELETE |
|----------|-----|------|-----|--------|
| `/api/init` | ✓ | | | |
| `/api/transactions` | ✓ | ✓ | | |
| `/api/transactions/{id}` | | | ✓ | ✓ |
| `/api/accounts` | ✓ | ✓ | | |
| `/api/accounts/{id}` | | | ✓ | ✓ |
| `/api/categories` | ✓ | ✓ | | |
| `/api/categories/{id}` | | | ✓ | ✓ |
| `/api/budgets` | ✓ | ✓ | | |
| `/api/budgets/{id}` | | | | ✓ |
| `/api/gold-prices` | ✓ | | | |
| `/api/gold-assets` | ✓ | ✓ | | |
| `/api/gold-assets/{id}` | | | | ✓ |
| `/api/settings` | ✓ | | ✓ | |
