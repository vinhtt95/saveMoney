# SaveMoney Mobile App — Data Models

## Transaction

```swift
struct Transaction: Identifiable, Codable {
    var id: String
    var date: String           // "YYYY-MM-DD"
    var type: TransactionType  // expense | income | account | transfer
    var categoryId: String?
    var accountId: String?
    var transferToId: String?  // chỉ dùng khi type = transfer
    var amount: Double         // âm với expense, dương với income
    var note: String?
}

enum TransactionType: String, Codable {
    case expense  = "Expense"
    case income   = "Income"
    case account  = "Account"   // cập nhật số dư tài khoản
    case transfer = "Transfer"
}
```

**Ghi chú:**
- `amount` luôn có dấu: expense → âm, income → dương
- `type = account`: dùng để điều chỉnh số dư tài khoản, không tính vào thu/chi
- `type = transfer`: `accountId` là tài khoản nguồn, `transferToId` là tài khoản đích

---

## Account

```swift
struct Account: Identifiable, Codable {
    var id: String
    var name: String
}

// Số dư được lưu riêng trong AppViewModel:
var accountBalances: [String: Double]  // accountId -> balance
```

**Số dư thực tế** = `accountBalances[id]` + tổng net từ transactions

---

## Category

```swift
struct Category: Identifiable, Codable {
    var id: String
    var name: String
    var type: CategoryType  // expense | income
}

enum CategoryType: String, Codable {
    case expense = "expense"
    case income  = "income"
}
```

---

## Budget

```swift
struct Budget: Identifiable, Codable {
    var id: String
    var name: String
    var limit: Double          // alias: limitAmount
    var dateStart: String      // "YYYY-MM-DD"
    var dateEnd: String        // "YYYY-MM-DD"
    var categoryIds: [String]
}
```

---

## Gold Models

```swift
struct GoldAsset: Identifiable, Codable {
    var id: String
    var brand: GoldBrand
    var productId: String
    var productName: String
    var quantity: Double       // đơn vị: lượng (1 lượng = 37.5g)
    var note: String?
    var createdAt: String?
    var currentSellPrice: Double?
}

struct GoldPriceItem: Identifiable, Codable {
    var id: String
    var name: String
    var buyPrice: Double?
    var sellPrice: Double?
    var brand: GoldBrand
}

enum GoldBrand: String, Codable, CaseIterable {
    case sjc   = "sjc"
    case btmc  = "btmc"
    case world = "world"
}

// Response từ /api/gold-prices
struct GoldPricesResponse: Decodable {
    var items: [GoldPriceItem]
    var usdVnd: Double          // tỷ giá USD/VND
    var fetchedAt: String       // ISO 8601
}

// Cache lưu trong UserDefaults
struct GoldPriceCache: Codable {
    var items: [GoldPriceItem]
    var fetchedAt: Date
    var usdVnd: Double
}
```

**Hằng số vàng:**
- 1 lượng = 37.5 gram
- 1 lượng = 1.2057 troy oz

---

## App Init Data

Dữ liệu trả về từ `GET /api/init`:

```swift
struct AppInitData: Codable {
    var transactions: [Transaction]
    var categories: [Category]
    var accounts: [Account]
    var accountBalances: [String: Double]  // accountId -> số dư gốc
    var budgets: [Budget]
    var goldAssets: [GoldAsset]
    var settings: [String: String]
}
```

---

## Settings Keys

| Key | Giá trị | Mô tả |
|-----|---------|-------|
| `default_transaction_type` | `"Expense"` \| `"Income"` | Loại giao dịch mặc định |
| `default_account_id` | String (UUID) | Tài khoản mặc định |
| `default_expense_category_id` | String (UUID) | Category chi mặc định |
| `default_income_category_id` | String (UUID) | Category thu mặc định |

---

## Request/Response Models

### Tạo / Cập nhật giao dịch

```swift
struct CreateTransactionRequest: Encodable {
    var date: String
    var type: TransactionType
    var categoryId: String?
    var accountId: String?
    var transferToId: String?
    var amount: Double
    var note: String?
}

// UpdateTransactionRequest có cùng cấu trúc
```

### Tạo / Cập nhật tài khoản

```swift
struct CreateAccountRequest: Encodable {
    var name: String
    var balance: Double?
}

struct UpdateAccountRequest: Encodable {
    var name: String
    var balance: Double?
}
```

### Tạo category

```swift
struct CreateCategoryRequest: Encodable {
    var name: String
    var type: CategoryType
}

// Update category chỉ gửi: { "name": String }
```

### Tạo budget

```swift
struct CreateBudgetRequest: Encodable {
    var name: String
    var limitAmount: Double
    var dateStart: String   // "YYYY-MM-DD"
    var dateEnd: String     // "YYYY-MM-DD"
    var categoryIds: [String]
}
```

### Tạo gold asset

```swift
struct CreateGoldAssetRequest: Encodable {
    var brand: GoldBrand
    var productId: String
    var productName: String
    var quantity: Double
    var note: String?
}
```
