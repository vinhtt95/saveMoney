# Use Case Specification

**Project:** saveMoney
**Version:** 1.0
**Last Updated:** 2026-04-02

**Actors:**
- **User** — người dùng duy nhất của ứng dụng (single-user app, không có authentication)

---

## UC-01: Xem Dashboard tổng quan

| Field | Content |
|-------|---------|
| **ID and Name** | UC-01: Xem Dashboard tổng quan |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User xem tổng quan tài chính của kỳ đang chọn: tổng thu, tổng chi, net flow và giao dịch gần đây |
| **Trigger** | User navigate tới `/` hoặc mở ứng dụng |
| **Preconditions** | App đã load xong dữ liệu từ backend (`/api/init`) |
| **Postconditions** | Dashboard hiển thị đúng số liệu của `selectedPeriod` |
| **Priority** | High |
| **Frequency of Use** | Mỗi khi mở app |
| **Business Rules** | BR-03, BR-15 |

### Normal Flow — 1.0

1. User mở ứng dụng hoặc click "Dashboard" trên sidebar
2. System hiển thị summary cards: Tổng Thu, Tổng Chi, Net Flow cho `selectedPeriod`
3. System hiển thị danh sách giao dịch gần nhất
4. User đọc thông tin

### Alternative Flows

**1.1 — Đổi period**
1. User chọn period khác (all / YYYY-MM) từ period picker
2. System filter lại transactions theo period mới
3. Summary cards và danh sách cập nhật tức thì

### Exceptions

**1.0.E1 — Chưa có dữ liệu**
1. Transactions rỗng
2. System hiển thị 0 cho tất cả metrics và thông báo "Chưa có giao dịch"

---

## UC-02: Thêm/Sửa/Xóa giao dịch

| Field | Content |
|-------|---------|
| **ID and Name** | UC-02: Thêm/Sửa/Xóa giao dịch |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User quản lý vòng đời giao dịch tài chính: tạo mới, chỉnh sửa inline, lọc danh sách, và xóa |
| **Trigger** | User navigate tới `/transactions` hoặc click nút "+" trên Dashboard |
| **Preconditions** | Có ít nhất 1 account và 1 category trong hệ thống |
| **Postconditions** | DB cập nhật; danh sách transactions re-render; summary cards cập nhật |
| **Priority** | High |
| **Frequency of Use** | Hàng ngày |
| **Business Rules** | BR-01, BR-02, BR-04, BR-05, BR-14, BR-15 |

### Normal Flow — Thêm giao dịch (1.0)

1. User click nút "Thêm giao dịch"
2. System mở `AddTransactionModal`
3. User chọn: type, date, category (nếu cần), account, amount, note (tùy chọn)
4. User submit
5. System validate dữ liệu
6. System POST `/api/transactions`, cập nhật AppContext
7. Modal đóng; giao dịch mới xuất hiện trong danh sách

### Normal Flow — Sửa giao dịch inline (2.0)

1. User click vào row giao dịch
2. System expand row, hiển thị `InlineEditForm`
3. User chỉnh sửa các field cần thay đổi
4. User click "Lưu"
5. System PUT `/api/transactions/:id`, cập nhật AppContext
6. Row collapse, hiển thị giá trị mới

### Normal Flow — Xóa giao dịch (3.0)

1. User click icon "Xóa" trên row
2. System xác nhận (nếu có confirm dialog)
3. System DELETE `/api/transactions/:id`, xóa khỏi AppContext
4. Row biến mất khỏi danh sách

### Alternative Flows

**1.1 — Tạo danh mục mới trong form**
1. User nhập tên danh mục mới trong Combobox category
2. System tạo category mới và tự động chọn nó

**1.2 — Lọc danh sách**
1. User nhập vào ô search hoặc chọn filter (category, account, type, date range)
2. System filter realtime, cập nhật danh sách và summary cards

### Exceptions

**1.0.E1 — Transfer thiếu tài khoản đích**
1. User chọn type=Transfer nhưng không chọn `transferToId`
2. System báo lỗi validation, không submit

**2.0.E1 — Conflict dữ liệu**
1. PUT request thất bại (network error, etc.)
2. System hiển thị lỗi, rollback optimistic update

---

## UC-03: Import CSV từ Savey

| Field | Content |
|-------|---------|
| **ID and Name** | UC-03: Import CSV từ Savey |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User import file CSV export từ Savey iOS để bulk load transactions vào hệ thống |
| **Trigger** | User navigate tới `/settings` → mục "Import CSV" |
| **Preconditions** | User có file CSV export từ Savey iOS app |
| **Postconditions** | Transactions được insert vào DB; không duplicate (INSERT IGNORE) |
| **Priority** | Medium |
| **Frequency of Use** | Lần đầu setup hoặc khi cần sync dữ liệu lớn |
| **Business Rules** | BR-11 |

### Normal Flow — 1.0

1. User drag & drop file CSV hoặc click "Chọn file"
2. System đọc file, parse bằng `csvParser.ts`
3. System hiển thị preview: số lượng giao dịch, các rows đầu tiên
4. User review và click "Import"
5. System POST `/api/transactions/bulk` với array transactions
6. MySQL INSERT IGNORE (tránh duplicate)
7. System hiển thị kết quả: "X giao dịch đã được import"
8. AppContext reload transactions

### Alternative Flows

**1.1 — File không đúng format**
1. System parse thất bại hoặc detect format không khớp
2. System hiển thị lỗi cụ thể, không tiến hành import

### Exceptions

**1.0.E1 — File rỗng hoặc không đọc được**
1. System báo lỗi "File không hợp lệ"

---

## UC-04: Xem Analytics & báo cáo chi tiêu

| Field | Content |
|-------|---------|
| **ID and Name** | UC-04: Xem Analytics & báo cáo chi tiêu |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User xem các biểu đồ và bảng số liệu phân tích chi tiêu theo danh mục, thời gian |
| **Trigger** | User navigate tới `/analytics` |
| **Preconditions** | Có giao dịch trong DB |
| **Postconditions** | Biểu đồ hiển thị đúng dữ liệu theo filter đã chọn |
| **Priority** | High |
| **Frequency of Use** | Hàng tuần / hàng tháng |
| **Business Rules** | BR-01, BR-02, BR-15 |

### Normal Flow — 1.0

1. User navigate tới `/analytics`
2. System render stacked bar chart: chi tiêu theo tháng × danh mục (top N)
3. System render category breakdown table với tổng và % tổng
4. User điều chỉnh: chọn date range, số danh mục hiển thị (top N)
5. System cập nhật biểu đồ realtime
6. User click vào một danh mục cụ thể
7. System hiển thị line chart trend danh mục đó theo tháng

### Alternative Flows

**1.1 — Xem category×month matrix**
1. User scroll xuống phần "Chi tiết theo danh mục và tháng"
2. System hiển thị bảng matrix: rows = danh mục, columns = tháng
3. User đọc từng ô

---

## UC-05: Quản lý Budget

| Field | Content |
|-------|---------|
| **ID and Name** | UC-05: Quản lý Budget |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User tạo ngân sách chi tiêu cho nhóm danh mục trong khoảng thời gian, theo dõi progress |
| **Trigger** | User navigate tới `/budget` |
| **Preconditions** | Có danh mục (categories) trong hệ thống |
| **Postconditions** | Budget được lưu; progress bar phản ánh chi tiêu thực tế |
| **Priority** | Medium |
| **Frequency of Use** | Hàng tháng |
| **Business Rules** | BR-06, BR-07, BR-14 |

### Normal Flow — Tạo Budget (1.0)

1. User click "Thêm Budget"
2. User nhập: name, limit (VND), dateStart, dateEnd, chọn categories (nhiều)
3. System validate: dateEnd ≥ dateStart
4. System POST `/api/budgets`, cập nhật AppContext
5. Budget mới hiển thị với progress bar = (chi tiêu thực / limit × 100)%

### Normal Flow — Theo dõi Budget (2.0)

1. User xem danh sách budgets
2. System tính tổng chi tiêu của các categories trong date range của mỗi budget
3. System hiển thị: progress bar, số tiền đã dùng, limit, % còn lại
4. Budget vượt limit hiển thị màu cảnh báo (đỏ)

### Normal Flow — Sửa/Xóa Budget (3.0)

1. User click edit/delete trên budget row
2. Sửa: System PUT `/api/budgets/:id`; Xóa: DELETE `/api/budgets/:id`
3. Danh sách cập nhật

### Exceptions

**1.0.E1 — dateEnd < dateStart**
1. System báo lỗi validation

---

## UC-06: Xem giá vàng thực tế

| Field | Content |
|-------|---------|
| **ID and Name** | UC-06: Xem giá vàng thực tế |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | SJC API, BTMC API, fxratesapi.com, Yahoo Finance |
| **Description** | User xem giá vàng mua/bán hiện tại từ SJC, BTMC và thị trường thế giới, kèm biểu đồ lịch sử |
| **Trigger** | User navigate tới `/gold` |
| **Preconditions** | Kết nối internet (để fetch giá mới); hoặc có cache hợp lệ |
| **Postconditions** | Giá vàng hiển thị; daily snapshot được lưu nếu chưa có |
| **Priority** | Medium |
| **Frequency of Use** | Hàng ngày |
| **Business Rules** | BR-08, BR-09, BR-10, BR-16, BR-17 |

### Normal Flow — 1.0

1. User navigate tới `/gold`
2. System gọi `goldPriceService.fetchGoldPrices()`
3. Nếu cache còn hạn (< 5 phút): dùng cache
4. Nếu cache hết hạn: parallel fetch SJC + BTMC + World
5. System parse và merge kết quả
6. System lưu cache mới vào localStorage
7. System gọi `goldHistoryService.maybeRecordTodaySnapshot()` — lưu snapshot nếu chưa có hôm nay
8. UI render: bảng giá SJC, bảng giá BTMC, thẻ giá thế giới, tỷ giá USD/VND
9. User chọn period (7d/30d/90d/all) và chọn tối đa 4 sản phẩm để compare
10. System render line chart lịch sử giá

### Alternative Flows

**1.1 — Một nguồn fetch thất bại**
1. Promise.allSettled — nguồn lỗi trả về null
2. System hiển thị dữ liệu từ các nguồn thành công, ẩn phần bị lỗi
3. Hiển thị thông báo lỗi nguồn cụ thể

**1.2 — Không có internet**
1. Fetch thất bại hoàn toàn
2. System dùng cache cũ nhất có thể (expired cache)
3. System hiển thị timestamp fetch cũ, cảnh báo "Dữ liệu có thể không mới nhất"

---

## UC-07: Quản lý tài sản vàng (Wealth)

| Field | Content |
|-------|---------|
| **ID and Name** | UC-07: Quản lý tài sản vàng |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | Gold Price Service |
| **Description** | User quản lý danh mục tài sản vàng đang sở hữu, xem giá trị hiện tại theo thị trường |
| **Trigger** | User navigate tới `/wealth` |
| **Preconditions** | — |
| **Postconditions** | Gold assets được lưu vào DB; tổng giá trị được tính theo giá hiện tại |
| **Priority** | Medium |
| **Frequency of Use** | Hàng tuần |
| **Business Rules** | BR-08, BR-09, BR-10 |

### Normal Flow — Thêm tài sản (1.0)

1. User click "Thêm tài sản vàng"
2. User chọn: brand (SJC/BTMC/world), sản phẩm từ danh sách, số lượng (lượng), ghi chú
3. System POST `/api/gold-assets`
4. Tài sản mới hiển thị với giá trị = quantity × giá bán hiện tại

### Normal Flow — Xem tổng giá trị (2.0)

1. User xem trang Wealth
2. System fetch giá hiện tại (hoặc dùng cache)
3. System tính: giá trị mỗi tài sản = quantity × sell price
4. System hiển thị tổng giá trị tài sản vàng (VND)

### Normal Flow — Sửa/Xóa tài sản (3.0)

1. User click edit/delete trên asset row
2. Sửa: System PUT `/api/gold-assets/:id`; Xóa: DELETE `/api/gold-assets/:id`

---

## UC-08: Quản lý tài khoản & số dư

| Field | Content |
|-------|---------|
| **ID and Name** | UC-08: Quản lý tài khoản & số dư |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User tạo/sửa/xóa tài khoản tài chính, cập nhật số dư ban đầu, xem số dư hiện tại |
| **Trigger** | User navigate tới `/accounts` |
| **Preconditions** | — |
| **Postconditions** | Account được lưu; net balance tính đúng |
| **Priority** | High |
| **Frequency of Use** | Lần đầu setup; sau đó ít thường xuyên |
| **Business Rules** | BR-03, BR-04 |

### Normal Flow — Tạo tài khoản (1.0)

1. User click "Thêm tài khoản"
2. User nhập: tên tài khoản, số dư ban đầu (optional)
3. System POST `/api/accounts` + PUT `/api/accounts/:id/balance`
4. Tài khoản mới hiển thị với net balance = initial_balance

### Normal Flow — Xem số dư (2.0)

1. User xem danh sách accounts
2. System tính: net balance = initial_balance + Σ(amount of account's transactions)
3. System hiển thị: initial balance, total income, total expense, net balance

### Normal Flow — Xem lịch sử giao dịch tài khoản (3.0)

1. User click vào một tài khoản
2. System hiển thị tất cả giao dịch của tài khoản đó
3. User xem chi tiết

### Exceptions

**1.0.E1 — Xóa tài khoản còn giao dịch**
1. Hành vi phụ thuộc implementation — nên cảnh báo trước

---

## UC-09: Backup/Restore dữ liệu

| Field | Content |
|-------|---------|
| **ID and Name** | UC-09: Backup/Restore dữ liệu |
| **Date Created** | 2026-04-02 |
| **Primary Actor** | User |
| **Secondary Actors** | — |
| **Description** | User export toàn bộ dữ liệu ra file JSON để backup, hoặc import lại để restore |
| **Trigger** | User navigate tới `/settings` → mục "Backup/Restore" |
| **Preconditions** | — |
| **Postconditions** | Backup: file JSON download. Restore: toàn bộ dữ liệu được ghi đè từ file |
| **Priority** | High |
| **Frequency of Use** | Định kỳ (hàng tháng) hoặc trước khi thay đổi lớn |
| **Business Rules** | BR-12 |

### Normal Flow — Export Backup (1.0)

1. User click "Export Backup"
2. System collect: transactions, categories, accounts, accountBalances, budgets, goldAssets, settings
3. System serialize thành JSON version 2
4. System trigger download file `savemoney-backup-YYYY-MM-DD.json`

### Normal Flow — Import/Restore (2.0)

1. User chọn file JSON backup
2. System đọc và parse file
3. Nếu version 1: `migration.ts` auto-convert sang version 2
4. System hiển thị summary: số lượng records mỗi entity
5. User confirm "Ghi đè toàn bộ dữ liệu"
6. System xóa data cũ và insert data mới
7. AppContext reload
8. System thông báo "Restore thành công"

### Alternative Flows

**2.1 — File version 1 (legacy)**
1. System detect `version: 1`
2. `migration.ts` convert: category/account name → ID mapping
3. Tiếp tục flow bình thường từ bước 4

### Exceptions

**2.0.E1 — File JSON không hợp lệ**
1. JSON.parse thất bại hoặc structure không đúng
2. System báo lỗi, không thực hiện restore

**2.0.E2 — User cancel sau khi xem summary**
1. Không thay đổi gì, dữ liệu cũ giữ nguyên
