---
name: feature-workflow
description: >
  Use this skill whenever the user wants to implement, change, add, or modify ANY feature or functionality in a codebase.
  Trigger on phrases like: "tao muốn thêm chức năng", "implement feature", "thay đổi tính năng", "sửa chức năng",
  "tao cần làm X trong project", "build feature", "add functionality", "modify feature", "tao muốn làm chức năng",
  "help me implement", "tao muốn thực hiện", "làm sao để thêm", "cần thay đổi", "cần implement".
  This skill enforces a strict 7-step structured workflow: Requirements Reading → Confirmation → Analysis & Solution Design
  → Solution Selection → Planning → Execution → Documentation & Knowledge Capture.
  ALWAYS trigger this skill before writing ANY code or making ANY implementation decisions when a user describes
  a feature request or code change, even if it sounds simple.
---

# Feature Implementation Workflow

Một workflow (quy trình) có cấu trúc để implement (triển khai) hoặc thay đổi tính năng trong bất kỳ project nào.
Workflow này gồm **7 bước bắt buộc** — không được bỏ qua bước nào, không được gộp bước.

---

## Bước 1 — Diễn giải yêu cầu (Interpret the Request)

### 1.1 — Đọc Requirements

Tìm và đọc toàn bộ tài liệu requirements (yêu cầu) của project trong thư mục `requirements/` hoặc tên tương đương (`docs/`, `spec/`, v.v.).

**Ưu tiên đọc theo thứ tự:**
1. `SRS.md` / `Software_Requirement_Specification.md` — chức năng hiện tại, tên gọi, business rules (quy tắc nghiệp vụ)
2. `Business_Rules.md` — các ràng buộc, quy tắc tính toán
3. `Vision_and_Scope.md` — phạm vi, mục tiêu kinh doanh
4. `UseCase.md` / `Overview.md` — actors (tác nhân), use case flows (luồng use case)

**Nếu project chưa có tài liệu requirements:**
→ Đọc toàn bộ codebase để suy ngược (reverse-engineer) requirements hiện tại.
→ Tạo các file markdown theo template tại `references/templates/` của skill này.
→ Báo cho user biết các file nào đã được tạo mới.

### 1.2 — Đọc Architecture (Kiến trúc)

Tìm và đọc tài liệu software architecture (kiến trúc phần mềm): `SAS.md`, `architecture.md`, `ARCHITECTURE.md`, v.v.

**Nếu chưa có:**
→ Phân tích codebase: folder structure (cấu trúc thư mục), tech stack (công nghệ), design patterns (mẫu thiết kế), data flow (luồng dữ liệu).
→ Tạo file `SAS.md` cơ bản và báo cho user.

### 1.3 — Diễn giải chi tiết

Kết hợp requirements + architecture + yêu cầu của user:
- Xác định chức năng nào đang bị ảnh hưởng
- Liệt kê các business rules liên quan (BR-ID)
- Xác định use cases liên quan (UC-ID)
- Liệt kê các component (thành phần) / module sẽ bị tác động
- Phát hiện các dependency (phụ thuộc) và integration points (điểm tích hợp)

**Output bước 1:** Một đoạn diễn giải ngắn gọn (<300 từ) mô tả tao hiểu yêu cầu như thế nào.

---

## Bước 2 — Xác nhận hiểu đúng yêu cầu (Confirm Understanding)

Trình bày lại yêu cầu của user bằng ngôn ngữ kỹ thuật / nghiệp vụ rõ ràng hơn — **khác cách diễn đạt của user** nhưng vẫn đúng ý.

Format output:
```
**Tao hiểu yêu cầu là:**
[Diễn đạt lại bằng ngôn ngữ hệ thống]

**Cụ thể:**
- [điểm 1]
- [điểm 2]
- ...

**Trong phạm vi này có:**
- [gì được bao gồm]

**Ngoài phạm vi này:**
- [gì không được bao gồm — nếu có]

---
Mày xác nhận tao hiểu đúng không?
```

**→ Dừng lại, chờ user xác nhận trước khi sang bước 3.**

---

## Bước 3 — Phân tích & Thiết kế giải pháp (Analysis & Solution Design)

### 3.1 — Bảng tiêu chí chấp nhận (Acceptance Criteria)

Tạo bảng tiêu chí để đánh giá giải pháp có đáp ứng yêu cầu không:

| ID | Tiêu chí | Mức độ quan trọng | Cách kiểm chứng |
|----|----------|-------------------|-----------------|
| AC-01 | [tiêu chí] | Must / Should / Nice-to-have | [cách test] |

### 3.2 — Bảng các phương án giải pháp

Tạo file `solution_options.md` trong thư mục làm việc. Với **mỗi phương án** cần có:

```markdown
## Phương án [N]: [Tên phương án]

**Mô tả:** [Giải thích ngắn gọn]

**Công nghệ / Công cụ áp dụng:** [tech stack, libraries, patterns]

**Files bị thay đổi:**
- `path/to/file.ext` — thay đổi gì, tại sao

**Đáp ứng tiêu chí:**
| AC-ID | Đáp ứng? | Ghi chú |
|-------|----------|---------|

**Ưu điểm:**
- ...

**Nhược điểm / Rủi ro:**
- ...
```

### 3.3 — Chuyển sang bước 4

Sau khi đã có đủ phương án → tiếp tục.

---

## Bước 4 — Lựa chọn giải pháp (Solution Selection)

Tạo file `solution_comparison.md` với bảng so sánh:

| Tiêu chí đánh giá | Phương án 1 | Phương án 2 | Phương án N |
|-------------------|-------------|-------------|-------------|
| Độ phức tạp triển khai | | | |
| Thời gian ước tính | | | |
| Rủi ro kỹ thuật | | | |
| Khả năng bảo trì | | | |
| Phù hợp kiến trúc hiện tại | | | |
| Chi phí / lợi ích tổng thể | | | |

Cuối file: **Đề xuất của Claude** — nêu rõ phương án nào được đề xuất và lý do ngắn gọn.

**→ Dừng lại. Present file cho user. Chờ user chọn phương án trước khi sang bước 5.**

---

## Bước 5 — Lên kế hoạch thực hiện (Implementation Plan)

Dựa trên phương án user chọn, tạo `implementation_plan.md`:

```markdown
# Implementation Plan (Kế hoạch triển khai)

## Phương án đã chọn: [tên]

## Tasks (Công việc)
| # | Task | File | Mô tả thay đổi | Phụ thuộc |
|---|------|------|----------------|-----------|
| 1 | | | | |

## Thứ tự thực hiện
[Mô tả thứ tự, dependency giữa các task]

## Rủi ro và phương án dự phòng
[Liệt kê rủi ro chính và cách xử lý]
```

**→ Confirm plan với user trước khi execute (thực thi).**

---

## Bước 6 — Thực hiện (Execute)

- Thực hiện theo đúng plan ở bước 5, từng task theo thứ tự
- Sau mỗi task quan trọng: báo cáo ngắn gọn "Task [N] ✓ — [mô tả đã làm gì]"
- Nếu gặp blocker (cản trở) không lường trước: dừng, mô tả vấn đề, hỏi user
- Không tự ý mở rộng scope (phạm vi) ngoài plan đã được chọn

---

## Bước 7 — Tổng kết & Cập nhật tài liệu (Close-out)

### 7.1 — Cập nhật SRS và SAS

- **SRS.md**: Cập nhật phần liên quan — thêm/sửa use case, business rule, functional requirement
- **SAS.md**: Cập nhật nếu có thay đổi về kiến trúc, component mới, data flow mới

### 7.2 — Tạo Change Log

Tạo file tại `Log Change/YYYY-MM-DD_[feature-name].md`:

```markdown
# Change Log: [Tên tính năng]

**Date (Ngày):** YYYY-MM-DD
**Author (Tác giả):** [user]
**Related:** [BR-ID, UC-ID, FA-ID nếu có]

## Hiện trạng trước khi thay đổi
[Mô tả trạng thái cũ — hệ thống làm gì, không làm gì, vấn đề gì tồn tại]

## Yêu cầu đã thực hiện
[Diễn giải ngắn gọn yêu cầu từ bước 2]

## Thay đổi đã thực hiện
| File | Loại thay đổi | Mô tả |
|------|---------------|-------|
| `path/to/file` | Added / Modified / Deleted | [chi tiết] |

## Tiêu chí chấp nhận — Kết quả kiểm tra
| AC-ID | Tiêu chí | Kết quả | Ghi chú |
|-------|----------|---------|---------|

## Bài học & Kinh nghiệm
- [lesson learned, edge case gặp phải, quyết định kỹ thuật đáng ghi nhớ]
```

---

## Quy tắc bất biến (Non-negotiable Rules)

1. **Không bao giờ bỏ qua bước.** Không gộp bước 1+2, không nhảy thẳng vào code.
2. **Bước 2 và Bước 4 luôn phải chờ user xác nhận** trước khi tiếp tục.
3. **Không tự ý mở rộng scope** trong bước 6 ngoài những gì đã plan.
4. **Nếu project không có requirements/architecture docs:** tạo trước, sau đó tiếp tục workflow.
5. **Tất cả file output** (solution_options, solution_comparison, implementation_plan, change log) phải được present cho user xem.

---

## Xử lý tình huống đặc biệt

| Tình huống | Hành động |
|-----------|-----------|
| Project không có `requirements/` folder | Scan toàn bộ codebase, tạo SRS + SAS cơ bản trước |
| Yêu cầu mâu thuẫn với business rule | Nêu rõ conflict (xung đột), hỏi user resolve (giải quyết) |
| Chỉ có 1 phương án khả thi | Vẫn viết đầy đủ, note rõ "đây là phương án duy nhất khả thi và lý do" |
| User muốn skip bước (vd: "code luôn đi") | Giải thích ngắn lý do không nên skip, nhưng tôn trọng quyết định của user |
| Bug fix thay vì feature mới | Vẫn áp dụng workflow, nhưng bước 1 tập trung vào root cause analysis |

---

## Templates

Xem chi tiết template tại `references/templates/`:
- `SRS_template.md` — Software Requirement Specification
- `SAS_template.md` — Software Architecture Specification
- `UseCase_template.md` — Use Case documentation
- `BusinessRules_template.md` — Business Rules table
