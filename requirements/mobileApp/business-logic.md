# SaveMoney Mobile App — Business Logic

## 1. Tính số dư tài khoản

Số dư thực tế của một tài khoản được tính theo công thức:

```
balance(accountId) = accountBalances[accountId] + netTotals[accountId]
```

Trong đó `netTotals` được tính bằng cách duyệt toàn bộ transactions:

| Điều kiện | Tác động |
|-----------|---------|
| type=income AND accountId match | +amount |
| type=expense AND accountId match | +amount (amount đã âm) |
| type=transfer AND accountId = source | -\|amount\| |
| type=transfer AND transferToId = dest | +\|amount\| |
| type=account | Bỏ qua (balance đã được đưa vào accountBalances) |

**Tổng số dư toàn app:**
```
totalBalance = Σ balance(accountId) cho tất cả accounts
```

---

## 2. Thống kê hàng tháng

Với một kỳ (YYYY-MM):

```
income   = Σ amount  (transactions where type=income AND date starts with YYYY-MM)
expense  = Σ |amount| (transactions where type=expense AND date starts with YYYY-MM)
remaining = income - expense
```

---

## 3. Tính tiến độ ngân sách (Budget)

```
spentAmount(budget) =
  Σ |amount|
  for transactions where:
    - type = expense
    - categoryId IN budget.categoryIds
    - date BETWEEN budget.dateStart AND budget.dateEnd

progress(budget) = min(spentAmount / budget.limit, 1.0)
```

**Trạng thái hiển thị:**
- progress < 0.8 → Xanh lá
- 0.8 ≤ progress < 1.0 → Cam
- progress ≥ 1.0 → Đỏ (Vượt ngân sách)

**Số tiền còn lại:**
- Nếu `spentAmount < limit`: `remaining = limit - spentAmount`
- Nếu `spentAmount ≥ limit`: hiển thị "Over budget"

---

## 4. Phân tích category breakdown

```
expenses = transactions where type=expense AND period match

perCategory = group by categoryId → sum |amount|

top5 = sort DESC by amount, lấy 5 category đầu
other = sum các category còn lại

percentage(cat) = cat.amount / totalExpense × 100
```

---

## 5. Biểu đồ chi tiêu theo thứ trong tuần

```
dayOfWeek(date) → 0 (Sun) ... 6 (Sat)

weekdayTotals[0..6] = Σ |amount| của expense transactions
  group by dayOfWeek(transaction.date)
  filtered by selected period
```

---

## 6. Dự báo chi tiêu cuối tháng

```
today = ngày hiện tại trong tháng
daysInMonth = tổng số ngày của tháng đó
daysElapsed = today (số ngày đã trôi qua, ít nhất = 1)

projectedTotal = (currentExpense / daysElapsed) × daysInMonth
```

Hiển thị khi đang xem tháng hiện tại, dùng để người dùng ước tính tổng chi tiêu tháng.

---

## 7. Tính giá trị tài sản vàng

```
value(asset) = asset.quantity × sellPrice(asset.brand, asset.productId)

sellPrice lấy từ GoldPriceService:
  └─ Tìm GoldPriceItem có brand = asset.brand AND id = asset.productId
       └─ Trả về item.sellPrice (nếu không tìm thấy → 0)

totalGoldValue = Σ value(asset) cho tất cả goldAssets
```

**Đơn vị:** `quantity` tính bằng **lượng**
- 1 lượng = 37.5 gram
- 1 lượng = 1.2057 troy oz

---

## 8. Net worth (Tổng tài sản ròng)

```
netWorth = totalBalance + totalGoldValue
```

Hiển thị trên Dashboard khi `totalGoldValue > 0`.

---

## 9. Cache giá vàng

```
TTL = 5 phút

fetchIfNeeded():
  ├─ Đọc cache từ UserDefaults
  ├─ Nếu cache tồn tại AND (now - cache.fetchedAt) < 5 phút
  │    └─ Dùng cache, không gọi API
  └─ Ngược lại → fetchFresh() → GET /api/gold-prices
                                  └─ Lưu lại cache với timestamp mới

fetchFresh(): Luôn gọi API, bỏ qua TTL check (dùng khi người dùng nhấn Refresh)
```

---

## 10. Default settings cho form giao dịch

Khi mở form tạo giao dịch mới, các giá trị mặc định được lấy từ `AppViewModel.settings`:

```
selectedType     ← settings["default_transaction_type"]  (fallback: .expense)
selectedAccount  ← settings["default_account_id"]
selectedCategory ← settings["default_expense_category_id"]
                   hoặc settings["default_income_category_id"]
                   (tùy theo selectedType)
```

Khi người dùng thay đổi loại giao dịch (Expense ↔ Income), category tự động chuyển sang default category tương ứng.

---

## 11. Phân trang giao dịch

```
PAGE_SIZE = 20

filtered() = áp dụng filter: searchText + categoryId + accountId + period
paged()    = filtered()[0 ..< currentPage × PAGE_SIZE]
hasMore()  = filtered().count > paged().count

loadMore() → currentPage += 1
reset()    → currentPage = 1 (gọi khi thay đổi filter)
```

---

## 12. Quy tắc dấu amount

| Type | Amount |
|------|--------|
| income | Dương (+) |
| expense | Âm (−) |
| transfer | Âm (−) từ góc độ tài khoản nguồn |
| account | Bất kỳ (cập nhật số dư) |

Khi hiển thị, UI lấy `abs(amount)` cho các trường hợp cần hiện số dương (expense stats, category breakdown, budget spent).

---

## 13. Xử lý Transfer

Khi type = Transfer:
- `accountId` = tài khoản nguồn (số dư giảm)
- `transferToId` = tài khoản đích (số dư tăng)
- `amount` = âm (tiền ra từ nguồn)
- Không tính vào income/expense stats
- Không tính vào category breakdown

---

## 14. Connection status

```
isConnected:
  ├─ GET /api/init thành công → true
  └─ Lỗi network / timeout / status ≥ 400 → false

Hiển thị badge trong Settings:
  ├─ isLoading = true → "Loading..." (xanh nhạt)
  ├─ isConnected = true → "Connected" (xanh)
  └─ isConnected = false → "Disconnected" (đỏ)
```
