# Use Case Template

## [UC-ID]: [Tên Use Case]

| Field | Content |
|-------|---------|
| **ID and Name** | UC-[N]: [Tên ngắn gọn] |
| **Created By** | | 
| **Date Created** | YYYY-MM-DD |
| **Primary Actor** | |
| **Secondary Actors** | |
| **Description** | [Mô tả ngắn mục đích use case] |
| **Trigger** | [Điều kiện kích hoạt] |
| **Preconditions** | [Điều kiện tiên quyết] |
| **Postconditions** | [Trạng thái hệ thống sau khi hoàn thành] |
| **Priority** | High / Medium / Low |
| **Frequency of Use** | [Tần suất sử dụng] |
| **Business Rules** | BR-[ID], BR-[ID] |

### Normal Flow (Luồng bình thường) — 1.0

1. [Actor] [hành động]
2. System [phản hồi]
3. ...

### Alternative Flows (Luồng thay thế)

**1.1 — [Tên luồng thay thế]**
1. [Điều kiện kích hoạt luồng thay thế]
2. ...

### Exceptions (Ngoại lệ)

**1.0.E1 — [Tên ngoại lệ]**
1. [Điều kiện]
2. System [xử lý]

---

# Business Rules Template

| ID | Rule Definition | Type | Static/Dynamic | Source |
|----|----------------|------|----------------|--------|
| BR-01 | | Fact | Static | |
| BR-02 | | Constraint | Dynamic | |
| BR-03 | | Action Enabler | Dynamic | |
| BR-04 | | Inference | Dynamic | |
| BR-05 | | Computation | Dynamic | |

## Rule Types Reference

| Type | Description | Example |
|------|-------------|---------|
| **Fact** | Sự thật hiển nhiên về domain | Mỗi user có một email duy nhất |
| **Constraint** | Ràng buộc hệ thống phải tuân thủ | Tên không được chứa ký tự đặc biệt |
| **Action Enabler** | Điều kiện kích hoạt hành động | Nếu hết quota → gửi thông báo |
| **Inference** | Suy luận từ điều kiện | Nếu không active 30 ngày → inactive |
| **Computation** | Công thức tính toán | Total = subtotal + shipping fee |
