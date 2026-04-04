# SaveMoney Mobile App — State Management

## Kiến trúc tổng quan

```
App
 └─ AppViewModel (@EnvironmentObject)   ← State toàn cục
      ├─ TransactionViewModel            ← State màn hình Transactions
      ├─ AccountViewModel                ← CRUD tài khoản
      ├─ BudgetViewModel                 ← CRUD + tính toán ngân sách
      ├─ GoldViewModel                   ← CRUD gold assets
      ├─ SettingsViewModel               ← Cấu hình app
      └─ GoldPriceService (Singleton)    ← Cache giá vàng
```

---

## AppViewModel

**Vai trò:** Container state trung tâm, được inject vào toàn bộ app qua `@EnvironmentObject`.

**Published properties:**

| Property | Type | Mô tả |
|----------|------|-------|
| `transactions` | `[Transaction]` | Toàn bộ giao dịch |
| `categories` | `[Category]` | Danh sách category |
| `accounts` | `[Account]` | Danh sách tài khoản |
| `accountBalances` | `[String: Double]` | Số dư gốc theo accountId |
| `budgets` | `[Budget]` | Danh sách ngân sách |
| `goldAssets` | `[GoldAsset]` | Tài sản vàng |
| `settings` | `[String: String]` | Settings key-value |
| `isLoading` | `Bool` | Đang tải dữ liệu |
| `loadError` | `String?` | Lỗi khi tải |
| `isConnected` | `Bool` | Kết nối backend thành công |

**Methods:**

| Method | Mô tả |
|--------|-------|
| `loadInitData()` | Gọi GET /api/init, cập nhật tất cả state |
| `reload()` | Alias cho loadInitData() |
| `category(for id)` | Tìm Category theo id |
| `account(for id)` | Tìm Account theo id |
| `accountNetTotals` | Tính net từ transactions cho mỗi account |
| `balance(for accountId)` | Số dư thực tế = base + net |
| `totalBalance` | Tổng số dư tất cả tài khoản |
| `totalGoldValue` | Tổng giá trị vàng |
| `totalNetWorth` | totalBalance + totalGoldValue |
| `monthlyStats(yyyyMM)` | (income, expense, remaining) cho tháng |

---

## TransactionViewModel

**Vai trò:** Quản lý state màn hình Transactions (filter, paging, CRUD).

**Published properties:**

| Property | Type | Mô tả |
|----------|------|-------|
| `searchText` | `String` | Text tìm kiếm |
| `selectedCategoryId` | `String?` | Filter theo category |
| `selectedAccountId` | `String?` | Filter theo account |
| `selectedPeriod` | `String?` | Filter theo YYYY-MM |
| `currentPage` | `Int` | Trang hiện tại (mỗi trang 20 items) |
| `isSubmitting` | `Bool` | Đang gọi API |
| `submitError` | `String?` | Lỗi khi submit |

**Methods:**

| Method | Mô tả |
|--------|-------|
| `filtered()` | Áp dụng tất cả filter, sort DESC by date |
| `paged()` | Lấy slice từ filtered() theo currentPage |
| `hasMore()` | Còn items chưa hiển thị? |
| `loadMore()` | currentPage += 1 |
| `resetPaging()` | Reset về trang 1 (gọi khi filter thay đổi) |
| `create(request)` | POST /api/transactions → thêm vào AppVM |
| `update(id, request)` | PUT /api/transactions/{id} → cập nhật AppVM |
| `delete(id)` | DELETE /api/transactions/{id} → xóa khỏi AppVM |

---

## AccountViewModel

**Vai trò:** CRUD tài khoản.

**Published properties:** `isSubmitting`, `submitError`

**Methods:**

| Method | Mô tả |
|--------|-------|
| `create(request)` | POST /api/accounts → thêm vào AppVM.accounts |
| `update(id, request)` | PUT /api/accounts/{id} → cập nhật AppVM |
| `delete(id)` | DELETE /api/accounts/{id} → xóa khỏi AppVM |

Sau mỗi thao tác, cập nhật tương ứng trong `AppViewModel.accounts` và `AppViewModel.accountBalances`.

---

## BudgetViewModel

**Vai trò:** CRUD ngân sách + tính toán tiến độ.

**Methods:**

| Method | Mô tả |
|--------|-------|
| `spentAmount(budget)` | Tổng chi tiêu trong phạm vi budget |
| `progress(budget)` | spentAmount / limit (0.0 → 1.0+) |
| `create(request)` | POST /api/budgets → thêm vào AppVM.budgets |
| `delete(id)` | DELETE /api/budgets/{id} → xóa khỏi AppVM |

---

## GoldViewModel

**Vai trò:** CRUD tài sản vàng + tính giá trị.

**Dependencies:** `GoldPriceService.shared`

**Methods:**

| Method | Mô tả |
|--------|-------|
| `sellPrice(brand, productId)` | Lấy giá bán từ GoldPriceService |
| `totalValueVND(assets)` | Tổng giá trị VND của danh sách assets |
| `createAsset(request)` | POST /api/gold-assets → thêm vào AppVM |
| `deleteAsset(id)` | DELETE /api/gold-assets/{id} → xóa khỏi AppVM |

---

## SettingsViewModel

**Vai trò:** Quản lý cấu hình base URL và defaults.

**Published properties:**

| Property | Type | Mô tả |
|----------|------|-------|
| `baseURL` | `String` | URL backend hiện tại |
| `isSaving` | `Bool` | Đang lưu |
| `saveError` | `String?` | Lỗi khi lưu |
| `saveSuccess` | `Bool` | Lưu thành công |

**Methods:**

| Method | Mô tả |
|--------|-------|
| `saveBaseURL()` | Lưu base URL vào UserDefaults + APIService |
| `saveDefaults()` | PUT /api/settings với các default values |

---

## GoldPriceService (Singleton)

**Vai trò:** Fetch và cache giá vàng.

```swift
static let shared = GoldPriceService()
```

**Published properties:**

| Property | Type | Mô tả |
|----------|------|-------|
| `prices` | `[GoldPriceItem]` | Danh sách giá vàng |
| `usdVnd` | `Double` | Tỷ giá USD/VND |
| `isFetching` | `Bool` | Đang fetch |
| `lastFetchError` | `String?` | Lỗi gần nhất |
| `lastFetchedAt` | `Date?` | Thời điểm fetch gần nhất |

**Cache:**
- Lưu trong `UserDefaults` bằng `JSONEncoder/Decoder`
- TTL = 5 phút
- Key: `"gold_price_cache"`

---

## ThemeManager

**Vai trò:** Quản lý theme sáng/tối.

```swift
@AppStorage("colorSchemePreference") var preference: String = "system"

// "system" → nil (theo OS)
// "light"  → .light
// "dark"   → .dark
```

---

## Luồng update state điển hình

### Thêm giao dịch

```
User submit form
  └─ TransactionViewModel.create(request)
       └─ POST /api/transactions
            └─ Nhận Transaction từ server
                 └─ AppViewModel.transactions.append(newTx)
                      └─ UI tự động cập nhật qua @Published
```

### Xóa giao dịch

```
User swipe delete
  └─ TransactionViewModel.delete(id)
       └─ DELETE /api/transactions/{id}
            └─ AppViewModel.transactions.removeAll { $0.id == id }
                 └─ UI tự cập nhật
```

### Reload toàn bộ

```
User nhấn Refresh / App khởi động
  └─ AppViewModel.loadInitData()
       └─ GET /api/init
            └─ Gán lại tất cả @Published properties
                 └─ Toàn bộ UI re-render
```
