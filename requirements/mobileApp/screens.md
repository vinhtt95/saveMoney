# SaveMoney Mobile App — Màn hình & Tính năng

## 1. Dashboard (Tab: Flow)

### Mục đích
Hiển thị tổng quan tài chính theo kỳ (tháng), bao gồm số dư, thu chi, và giao dịch gần đây.

### Thành phần UI

| Thành phần | Mô tả |
|-----------|-------|
| Period selector | Chip buttons chọn tháng (tháng hiện tại + 5 tháng trước) |
| Hero card | Tổng số dư tất cả tài khoản (format VND) |
| Net worth card | Hiển thị khi có tài sản vàng: tổng tài sản (tiền + vàng) |
| Stat cards (2×2) | Income / Expense / Remaining / Total Balance |
| Recent transactions | 10 giao dịch gần nhất, nhấn để sửa |
| Refresh button | Tải lại toàn bộ dữ liệu từ API |

### Luồng tương tác

```
Chọn period
  └─ Lọc transactions theo YYYY-MM
       └─ Tính lại monthlyStats (income, expense, remaining)

Nhấn giao dịch gần đây
  └─ Mở AddTransactionView (edit mode)

Nhấn Refresh
  └─ AppViewModel.reload()
       └─ GET /api/init
```

---

## 2. Transactions (Tab: History)

### Mục đích
Xem toàn bộ lịch sử giao dịch với khả năng lọc, tìm kiếm, phân trang.

### Thành phần UI

| Thành phần | Mô tả |
|-----------|-------|
| Search bar | Tìm theo nội dung ghi chú |
| Category filter chips | Hiển thị tối đa 8 category đầu tiên, nhấn để lọc |
| Transaction list | Group theo ngày (Today / Yesterday / dd/MM/yyyy) |
| Pagination | 20 giao dịch/trang, nút "Load More" |
| Swipe-to-delete | Vuốt trái để xóa giao dịch |
| Tap to edit | Nhấn row để mở form sửa |
| Pull-to-refresh | Kéo xuống để tải lại |

### Luồng lọc

```
Nhập search text / chọn category
  └─ TransactionViewModel.filtered()
       ├─ Filter by note (case-insensitive contains)
       ├─ Filter by categoryId
       └─ Sort by date DESC

Cuộn đến cuối / nhấn Load More
  └─ TransactionViewModel.loadMore()
       └─ Tăng currentPage, hiển thị thêm 20 items
```

### Luồng xóa giao dịch

```
Vuốt trái → nhấn Delete
  └─ DELETE /api/transactions/{id}
       └─ Xóa khỏi AppViewModel.transactions[]
```

---

## 3. Analytics (Tab: Insight)

### Mục đích
Phân tích chi tiêu theo biểu đồ, giúp nhận ra xu hướng và thói quen chi tiêu.

### Thành phần UI

| Thành phần | Mô tả |
|-----------|-------|
| Period selector | Chọn tháng để phân tích |
| Category breakdown | Donut chart + legend, top 5 categories theo chi tiêu |
| Day-of-week chart | Bar chart tổng chi tiêu theo thứ trong tuần (CN–T7) |
| Projected trajectory | Dự báo chi tiêu đến cuối tháng |

### Logic tính toán

```
Category breakdown:
  └─ Lọc transactions type=expense theo period
       └─ Group by categoryId
            └─ Tính % = categoryAmount / totalExpense × 100
                 └─ Hiển thị top 5, gộp phần còn lại thành "Other"

Day-of-week:
  └─ Lọc expense transactions theo period
       └─ Map date → weekday (0=Sun ... 6=Sat)
            └─ Sum amount per weekday

Projected:
  └─ expense đã chi / số ngày đã qua × tổng số ngày trong tháng
```

---

## 4. Settings (Tab: Profile)

### Mục đích
Cấu hình ứng dụng, quản lý danh mục dữ liệu, và kết nối backend.

### Thành phần UI & Điều hướng

| Mục | Hành động |
|-----|-----------|
| Theme selector | System / Light / Dark — lưu vào UserDefaults |
| Budget | Navigate → BudgetView |
| Accounts | Navigate → AccountsView |
| Categories | Navigate → CategoriesView |
| Gold prices | Navigate → GoldView |
| Wealth (Net worth) | Navigate → WealthView |
| Base URL | TextField + nút Save → PUT /api/settings |
| Connection status | Badge: Connected / Disconnected / Loading |
| Default settings | Loại giao dịch, tài khoản, danh mục mặc định → PUT /api/settings |
| App info | SaveMoney v1.0.0 |

---

## 5. Add / Edit Transaction (Modal Sheet)

### Mở từ
- Nút **+** ở tab bar → tạo mới
- Nhấn vào giao dịch bất kỳ → sửa

### Thành phần form

| Field | Mô tả |
|-------|-------|
| Amount | Input số lớn, bàn phím số, định dạng VND |
| Type selector | Expense / Income / Transfer |
| Category picker | Sheet chọn category (lọc theo type) |
| Account picker | Sheet chọn tài khoản (hiện số dư) |
| Transfer To | Chỉ hiện khi type=Transfer; chọn tài khoản đích |
| Date picker | Sheet chọn ngày |
| Note | TextField tùy chọn |
| Delete button | Chỉ hiện khi edit mode |

### Pre-fill defaults
Form tự điền từ settings:
- `default_transaction_type` → loại giao dịch
- `default_account_id` → tài khoản
- `default_expense_category_id` / `default_income_category_id` → danh mục

### Luồng tạo mới

```
Điền form → nhấn Save
  └─ Validate amount > 0
       └─ POST /api/transactions
            Body: { date, type, categoryId, accountId, transferToId, amount, note }
            └─ Thêm vào AppViewModel.transactions[]
                 └─ Đóng sheet
```

### Luồng cập nhật

```
Sửa field → nhấn Save
  └─ PUT /api/transactions/{id}
       Body: { date, type, categoryId, accountId, transferToId, amount, note }
       └─ Cập nhật item trong AppViewModel.transactions[]
```

---

## 6. Accounts Management

### Mở từ: Settings → Accounts

### Tính năng

| Hành động | Luồng |
|-----------|-------|
| Xem danh sách | List tài khoản + số dư (xanh nếu >0, đỏ nếu ≤0) |
| Thêm tài khoản | Nhấn + → AccountFormView → POST /api/accounts |
| Sửa tài khoản | Nhấn vào card → AccountFormView → PUT /api/accounts/{id} |
| Xóa tài khoản | Vuốt trái → DELETE /api/accounts/{id} |

### Tính số dư tài khoản

```
balance(accountId) = accountBalances[accountId] + netTotals[accountId]

netTotals[accountId]:
  └─ Duyệt tất cả transactions:
       - type=income, accountId match → cộng amount
       - type=expense, accountId match → cộng amount (đã là âm)
       - type=transfer, accountId=source → trừ |amount|
       - type=transfer, transferToId=dest → cộng |amount|
```

---

## 7. Categories Management

### Mở từ: Settings → Categories

### Tính năng

| Hành động | Luồng |
|-----------|-------|
| Xem danh sách | Tách 2 section: Expense / Income |
| Thêm category | Nhấn + → CategoryFormView → POST /api/categories |
| Sửa tên | Vuốt trái → CategoryEditView → PUT /api/categories/{id} |
| Xóa category | Vuốt phải → DELETE /api/categories/{id} |

---

## 8. Budget Management

### Mở từ: Settings → Budget

### Thành phần hiển thị

Mỗi budget card hiển thị:
- Tên ngân sách + số tiền còn lại
- Progress bar (màu theo % sử dụng)
- Spent vs Limit
- Khoảng thời gian (dateStart → dateEnd)

### Màu progress bar

| Trạng thái | Điều kiện | Màu |
|-----------|-----------|-----|
| Bình thường | < 80% | Xanh lá |
| Cảnh báo | 80–99% | Cam |
| Vượt ngân sách | ≥ 100% | Đỏ |

### Luồng tạo budget

```
Nhấn + → AddBudgetView
  ├─ Nhập tên, số tiền giới hạn
  ├─ Chọn ngày bắt đầu / kết thúc
  ├─ Multi-select expense categories
  └─ POST /api/budgets
       Body: { name, limitAmount, dateStart, dateEnd, categoryIds[] }
```

---

## 9. Gold Prices View

### Mở từ: Settings → Gold prices

### Thành phần UI

| Thành phần | Mô tả |
|-----------|-------|
| USD/VND rate | Tỷ giá hiện tại |
| SJC section | Giá mua / bán các sản phẩm SJC |
| BTMC section | Giá mua / bán các sản phẩm BTMC |
| World Gold section | Giá vàng thế giới |
| Refresh button | Gọi GET /api/gold-prices bỏ qua cache |

### Cache strategy

```
Khi mở GoldView
  └─ GoldPriceService.fetchIfNeeded()
       ├─ Có cache AND cache < 5 phút → dùng cache (không gọi API)
       └─ Không có cache HOẶC cache > 5 phút → GET /api/gold-prices
            └─ Lưu vào UserDefaults với timestamp
```

---

## 10. Wealth View (Net Worth)

### Mở từ: Settings → Wealth

### Thành phần UI

| Thành phần | Mô tả |
|-----------|-------|
| Net worth hero card | Tổng tài sản = Số dư tài khoản + Giá trị vàng |
| Breakdown | Hiển thị riêng: Gold value / Account balance |
| Gold assets list | Danh sách tài sản vàng với giá trị hiện tại |
| Add button | Thêm tài sản vàng mới |

### Tính giá trị vàng

```
totalGoldValue =
  Σ (asset.quantity × sellPrice(asset.brand, asset.productId))

sellPrice lấy từ GoldPriceService.prices[]
  └─ Tìm theo brand và productId
```

### Luồng thêm tài sản vàng

```
Nhấn + → AddGoldAssetView
  ├─ Chọn brand (SJC / BTMC / World)
  ├─ Chọn sản phẩm từ danh sách giá
  ├─ Nhập số lượng (đơn vị: lượng)
  ├─ Nhập ghi chú (tùy chọn)
  └─ POST /api/gold-assets
       Body: { brand, productId, productName, quantity, note }
```
