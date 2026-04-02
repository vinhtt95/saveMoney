# Business Rules — saveMoney

**Project:** saveMoney
**Version:** 1.0
**Last Updated:** 2026-04-02

---

## Business Rules Table

| ID | Rule Definition | Type | Static/Dynamic | Source |
|----|----------------|------|----------------|--------|
| BR-01 | Mỗi giao dịch phải thuộc một trong 4 loại: `Expense`, `Income`, `Account`, `Transfer` | Constraint | Static | `src/types/index.ts` – `TransactionType` |
| BR-02 | Giá trị `amount` mang dấu: Expense và đầu ra của Transfer là số âm; Income và đầu vào của Transfer là số dương | Computation | Static | `src/types/index.ts` – `Transaction.amount` comment |
| BR-03 | Số dư tài khoản = `initial_balance` (account_balances) + tổng tất cả `amount` của giao dịch thuộc tài khoản đó | Computation | Dynamic | `src/utils/analytics.ts` – `getAccountNetTotals()` |
| BR-04 | Giao dịch loại `Transfer` phải có `transferToId` hợp lệ trỏ tới tài khoản đích | Constraint | Dynamic | `src/types/index.ts` – `Transaction.transferToId` |
| BR-05 | Giao dịch loại `Account` (điều chỉnh số dư) không bắt buộc có `categoryId` | Constraint | Static | `src/types/index.ts` – `TransactionType` |
| BR-06 | `Budget.dateEnd` phải lớn hơn hoặc bằng `Budget.dateStart` (định dạng `YYYY-MM-DD`) | Constraint | Dynamic | `src/types/index.ts` – `Budget` |
| BR-07 | Một Budget có thể liên kết với nhiều danh mục (`categoryIds: string[]`) | Fact | Static | `src/types/index.ts` – `Budget.categoryIds` |
| BR-08 | Đơn vị tài sản vàng là **lượng** (1 lượng = 37.5g). Quy đổi sang troy oz: 37.5 / 31.1035 ≈ 1.2057 | Computation | Static | `src/services/goldPriceService.ts` – `TROY_OZ_PER_LUONG` |
| BR-09 | Giá vàng được cache trong `localStorage` với TTL = **5 phút**. Sau TTL phải fetch lại từ nguồn | Action Enabler | Dynamic | `src/services/goldPriceService.ts` – `CACHE_TTL_MS = 5 * 60 * 1000` |
| BR-10 | Hệ thống chỉ hỗ trợ 3 nguồn giá vàng: `SJC`, `BTMC`, `world` (XAUUSD). Không thêm nguồn khác | Constraint | Static | `src/types/index.ts` – `GoldBrand` |
| BR-11 | File CSV import phải khớp format export từ ứng dụng Savey iOS. Các cột không đúng format sẽ bị reject | Constraint | Dynamic | `src/utils/csvParser.ts` |
| BR-12 | Định dạng file backup JSON là **version 2**. Version 1 vẫn được hỗ trợ migration tự động | Fact | Dynamic | `src/types/index.ts` – `DatabaseBackup.version` |
| BR-13 | Mỗi loại giao dịch có cài đặt mặc định riêng: `defaultCategoryExpenseId`, `defaultCategoryIncomeId`, `defaultAccountId` | Fact | Dynamic | `server/routes/settings.ts` |
| BR-14 | Danh mục (`Category`) có type `Expense` hoặc `Income` — không được lẫn lộn giữa hai loại | Constraint | Static | `src/types/index.ts` – `Category.type` |
| BR-15 | Period filter chỉ nhận 2 giá trị: `"all"` (toàn bộ lịch sử) hoặc `"YYYY-MM"` (theo tháng). Không có granularity theo tuần hay ngày | Constraint | Static | `src/types/index.ts` – `AppState.selectedPeriod` |
| BR-16 | Tỷ giá USD/VND fallback là 25,400 VND/USD khi không fetch được API tỷ giá | Fact | Dynamic | `src/services/goldPriceService.ts` – `FALLBACK_USDVND` |
| BR-17 | Giá vàng thế giới được snapshot theo ngày và lưu vào `localStorage` để vẽ biểu đồ lịch sử. Mỗi ngày chỉ lưu 1 snapshot | Constraint | Dynamic | `src/services/goldHistoryService.ts` |

---

## Rule Types Reference

| Type | Mô tả | Ví dụ trong saveMoney |
|------|-------|----------------------|
| **Fact** | Sự thật hiển nhiên về domain | 1 lượng = 37.5g |
| **Constraint** | Ràng buộc hệ thống phải tuân thủ | Transfer phải có transferToId |
| **Action Enabler** | Điều kiện kích hoạt hành động | Cache hết hạn → fetch lại giá vàng |
| **Inference** | Suy luận từ điều kiện | _(chưa có trong hệ thống)_ |
| **Computation** | Công thức tính toán | Net balance = initial + sum(transactions) |
