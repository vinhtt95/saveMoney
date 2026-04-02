# Software Requirement Specification (SRS)

**Project:** saveMoney
**Version:** 1.0
**Last Updated:** 2026-04-02

---

## 1. Introduction (Giới thiệu)

### 1.1 Purpose (Mục đích)

Tài liệu này mô tả các yêu cầu chức năng và phi chức năng của ứng dụng **saveMoney** — một dashboard quản lý tài chính cá nhân chạy trên nền web. Mục đích là làm nền tảng cho phát triển, kiểm thử, và bảo trì hệ thống.

### 1.2 Scope (Phạm vi)

saveMoney là ứng dụng single-user chạy trên desktop browser. Hệ thống:
- Nhập và quản lý giao dịch tài chính (Expense, Income, Transfer, Account adjustment)
- Cung cấp analytics chi tiêu theo danh mục và thời gian
- Theo dõi ngân sách (Budget) với giới hạn chi tiêu
- Hiển thị giá vàng thực tế từ SJC, BTMC, và thị trường thế giới
- Quản lý tài sản vàng (Wealth) với định giá theo thời gian thực
- Hỗ trợ import dữ liệu từ ứng dụng Savey iOS qua file CSV
- Backup/restore toàn bộ dữ liệu dưới dạng JSON

### 1.3 Definitions & Acronyms (Định nghĩa & Từ viết tắt)

| Term | Definition |
|------|------------|
| VND | Đồng Việt Nam — đơn vị tiền tệ chính của hệ thống |
| Lượng | Đơn vị khối lượng vàng truyền thống Việt Nam (1 lượng = 37.5g) |
| SJC | Công ty TNHH MTV Vàng bạc Đá quý Sài Gòn — nguồn giá vàng |
| BTMC | Công ty Vàng bạc Đá quý Bảo Tín Minh Châu — nguồn giá vàng |
| World Gold | Giá vàng thế giới theo USD/troy oz (XAUUSD), quy đổi sang VND/lượng |
| Expense | Giao dịch chi tiêu — amount âm |
| Income | Giao dịch thu nhập — amount dương |
| Transfer | Chuyển tiền giữa 2 tài khoản |
| Account | Điều chỉnh số dư tài khoản (không phải giao dịch thực) |
| Budget | Ngân sách đặt trước cho một nhóm danh mục trong khoảng thời gian |
| Period | Khoảng thời gian lọc: `"all"` hoặc `"YYYY-MM"` |
| FA | Functional Attribute — yêu cầu chức năng |
| NFR | Non-Functional Requirement — yêu cầu phi chức năng |
| BR | Business Rule — quy tắc nghiệp vụ |
| UC | Use Case |

---

## 2. System Overview (Tổng quan hệ thống)

saveMoney là ứng dụng web single-user phục vụ quản lý tài chính cá nhân. Hệ thống gồm:

- **Frontend SPA** (React + TypeScript): giao diện người dùng chạy trên browser
- **Backend API** (Express + Node.js): xử lý nghiệp vụ và persist data
- **Database** (MySQL): lưu trữ bền vững tất cả dữ liệu
- **External APIs**: SJC, BTMC, fxratesapi.com, Yahoo Finance — cung cấp giá vàng và tỷ giá

Người dùng chính: cá nhân muốn theo dõi tài chính, đặc biệt tương thích với dữ liệu export từ Savey iOS app.

---

## 3. Functional Requirements (Yêu cầu chức năng)

---

### FA-01: Dashboard — Tổng quan tài chính

**Mô tả:** Trang chủ hiển thị tổng quan trạng thái tài chính, các chỉ số nhanh, và giao dịch gần đây.

**Actor:** User

**Input:** Dữ liệu từ AppState (transactions, accounts, categories)

**Output:**
- Tổng thu nhập, tổng chi tiêu, net flow của kỳ đã chọn
- Danh sách giao dịch gần đây
- Quick stats và summary cards

**Business Rules:** BR-03, BR-15

---

### FA-02: Transaction Management — Quản lý giao dịch

**Mô tả:** Cho phép user xem, thêm, sửa, xóa giao dịch. Hỗ trợ filter đa chiều và inline editing.

**Actor:** User

**Input:**
- Thêm/Sửa: date, type (Expense/Income/Account/Transfer), category, account, amount, note
- Filter: search text, categoryIds, accountIds, types, dateStart/dateEnd
- Period: `"all"` hoặc `"YYYY-MM"`

**Output:**
- Danh sách giao dịch được group theo ngày, phân trang
- Summary: Total Income, Total Expenses, Net Flow
- Inline edit form trực tiếp trên row

**Business Rules:** BR-01, BR-02, BR-04, BR-05, BR-14, BR-15

---

### FA-03: Analytics — Phân tích chi tiêu

**Mô tả:** Hiển thị báo cáo chi tiêu dưới dạng biểu đồ và bảng số liệu.

**Actor:** User

**Input:** Bộ filter (period range, top N categories)

**Output:**
- Stacked bar chart: chi tiêu theo tháng và danh mục
- Line chart: trend một danh mục theo thời gian
- Category breakdown bảng: danh mục × tháng (matrix)
- Month-over-month comparison

**Business Rules:** BR-01, BR-02, BR-15

---

### FA-04: Budget Management — Quản lý ngân sách

**Mô tả:** Tạo và theo dõi ngân sách giới hạn chi tiêu theo danh mục và khoảng thời gian.

**Actor:** User

**Input:**
- Tạo/Sửa: name, limit (VND), dateStart, dateEnd, categoryIds (nhiều)
- Xóa: budgetId

**Output:**
- Danh sách budgets với progress bar (% đã dùng / limit)
- Tổng chi tiêu thực tế của các category trong date range
- Inline editing trực tiếp trên row giao dịch liên quan

**Business Rules:** BR-06, BR-07, BR-14

---

### FA-05: Gold Price Tracking — Theo dõi giá vàng

**Mô tả:** Hiển thị giá vàng thực tế từ nhiều nguồn, kèm biểu đồ lịch sử giá.

**Actor:** User

**Input:** Chọn period (7d, 30d, 90d, all), chọn sản phẩm để compare (tối đa 4)

**Output:**
- Giá mua/bán từ SJC (nhiều sản phẩm)
- Giá mua/bán từ BTMC (nhiều sản phẩm)
- Giá thế giới XAUUSD spot và futures, quy đổi VND/lượng
- Tỷ giá USD/VND hiện tại
- Line chart lịch sử giá các sản phẩm được chọn
- Timestamp lần fetch cuối

**Business Rules:** BR-08, BR-09, BR-10, BR-16, BR-17

---

### FA-06: Wealth Management — Quản lý tài sản vàng

**Mô tả:** Quản lý danh mục tài sản vàng đang sở hữu, định giá theo giá thị trường hiện tại.

**Actor:** User

**Input:**
- Thêm/Sửa: brand (SJC/BTMC/world), productId, productName, quantity (lượng), note
- Xóa: assetId

**Output:**
- Danh sách tài sản vàng với giá trị quy đổi theo giá hiện tại
- Tổng giá trị tài sản vàng (VND)
- Phân nhóm theo brand

**Business Rules:** BR-08, BR-09, BR-10

---

### FA-07: Account Management — Quản lý tài khoản

**Mô tả:** Tạo và quản lý các tài khoản tài chính (ví tiền mặt, tài khoản ngân hàng, v.v.).

**Actor:** User

**Input:**
- Tạo/Sửa/Xóa tài khoản: name
- Cập nhật initial balance (account_balances)

**Output:**
- Danh sách tài khoản với số dư hiện tại (net balance)
- Tổng số dư tất cả tài khoản
- Lịch sử giao dịch của từng tài khoản

**Business Rules:** BR-03, BR-04

---

### FA-08: Category Management — Quản lý danh mục

**Mô tả:** Tạo và quản lý danh mục cho Expense và Income.

**Actor:** User

**Input:** Thêm/Xóa category: name, type (Expense/Income)

**Output:**
- Split view: danh sách categories + giao dịch của category được chọn
- Số giao dịch và tổng chi tiêu per category
- 2 tab: Expenses / Income

**Business Rules:** BR-14

---

### FA-09: Settings & Data Management — Cài đặt và Quản lý dữ liệu

**Mô tả:** Cấu hình mặc định hệ thống và các chức năng import/export/backup dữ liệu.

**Actor:** User

**Sub-features:**

**FA-09a — CSV Import:**
- Input: File CSV từ Savey iOS export (drag & drop hoặc file picker)
- Output: Preview trước khi commit, bulk insert vào DB
- Business Rules: BR-11

**FA-09b — CSV Export:**
- Input: Filter hiện tại (period, categories, ...)
- Output: File CSV download với preview

**FA-09c — JSON Backup:**
- Output: File `savemoney-backup-YYYY-MM-DD.json` (version 2 format)
- Business Rules: BR-12

**FA-09d — JSON Restore:**
- Input: File JSON backup (version 1 hoặc 2)
- Output: Ghi đè toàn bộ dữ liệu (categories, accounts, transactions, budgets, gold assets)
- Business Rules: BR-12

**FA-09e — Default Settings:**
- Cấu hình: defaultCategoryExpenseId, defaultCategoryIncomeId, defaultAccountId
- Business Rules: BR-13

**FA-09f — Clear All Data:**
- Xóa toàn bộ dữ liệu trong DB

---

## 4. Non-Functional Requirements (Yêu cầu phi chức năng)

| ID | Loại | Mô tả | Tiêu chí đo lường |
|----|------|-------|-------------------|
| NFR-01 | Performance | Tải danh sách giao dịch nhanh | Render < 1s với ≤ 10,000 giao dịch |
| NFR-02 | Performance | Fetch giá vàng không block UI | Cache hit: 0ms; Fetch mới: async, hiển thị loading spinner |
| NFR-03 | Usability | Giao diện tiếng Việt | Tất cả label, placeholder, thông báo lỗi bằng tiếng Việt |
| NFR-04 | Usability | Responsive layout | Chạy tốt trên màn hình ≥ 1280px |
| NFR-05 | Data Integrity | Không mất dữ liệu khi import | CSV import phải preview và confirm trước khi ghi |
| NFR-06 | Data Integrity | Backup đầy đủ | JSON backup phải bao gồm 100% data (transactions, categories, accounts, budgets, gold assets, settings) |
| NFR-07 | Security | Không expose credentials | DB password, API keys không được log hoặc trả về frontend |
| NFR-08 | Localization | Định dạng số VND | Số tiền hiển thị định dạng `x.xxx.xxx ₫` |
| NFR-09 | Availability | Chạy local | App chạy trên `localhost:3000` + `localhost:3001`, không cần internet (ngoại trừ giá vàng) |

---

## 5. Business Rules Summary (Tóm tắt Quy tắc Nghiệp vụ)

Xem chi tiết tại [BusinessRules.md](BusinessRules.md).

| ID | Tóm tắt |
|----|---------|
| BR-01 | 4 loại giao dịch: Expense, Income, Account, Transfer |
| BR-02 | Amount mang dấu: Expense/Transfer-out âm, Income/Transfer-in dương |
| BR-03 | Net balance = initial_balance + Σ(amount) |
| BR-04 | Transfer bắt buộc có transferToId |
| BR-05 | Account-type transaction không cần category |
| BR-06 | Budget: dateEnd ≥ dateStart |
| BR-07 | Budget có thể map nhiều categories |
| BR-08 | Đơn vị vàng: lượng (37.5g) |
| BR-09 | Gold price cache TTL = 5 phút |
| BR-10 | 3 nguồn vàng: SJC, BTMC, world |
| BR-11 | CSV import phải đúng format Savey iOS |
| BR-12 | Backup format version 2 (v1 auto-migrate) |
| BR-13 | Default: category expense/income, account |
| BR-14 | Category type: Expense hoặc Income |
| BR-15 | Period: `"all"` hoặc `"YYYY-MM"` |
| BR-16 | Fallback USD/VND = 25,400 |
| BR-17 | Gold history: 1 snapshot / ngày |

---

## 6. Use Case Overview (Tổng quan Use Case)

Xem chi tiết tại [UseCase.md](UseCase.md).

| Actor | Use Cases |
|-------|-----------|
| User | UC-01: Xem Dashboard tổng quan |
| User | UC-02: Thêm/Sửa/Xóa giao dịch |
| User | UC-03: Import CSV từ Savey |
| User | UC-04: Xem Analytics & báo cáo chi tiêu |
| User | UC-05: Quản lý Budget |
| User | UC-06: Xem giá vàng thực tế |
| User | UC-07: Quản lý tài sản vàng (Wealth) |
| User | UC-08: Quản lý tài khoản & số dư |
| User | UC-09: Backup/Restore dữ liệu |

---

## 7. Constraints & Assumptions (Ràng buộc & Giả định)

**Constraints:**
- Ứng dụng chỉ hỗ trợ đơn tệ VND (không multi-currency)
- Phải chạy local với MySQL — không có cloud deployment
- Gold price APIs là bên thứ ba, có thể không ổn định
- Chỉ một người dùng — không có multi-user hay authentication
- Import CSV chỉ hỗ trợ format Savey iOS

**Assumptions:**
- User đã có MySQL server chạy local với database `savemoney_db`
- User đã cài Node.js và chạy được `npm run dev`
- Kết nối internet cần thiết để fetch giá vàng (không bắt buộc cho các tính năng khác)
- Dữ liệu export từ Savey iOS là nguồn dữ liệu gốc cho lần setup đầu tiên

---

## 8. Change History (Lịch sử thay đổi)

| Date | Version | Change | Author |
|------|---------|--------|--------|
| 2026-04-02 | 1.0 | Initial SRS — reverse-engineered từ codebase | Claude |
