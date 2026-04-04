# SaveMoney Mobile App — Tổng quan

## Mô tả ứng dụng

SaveMoney là ứng dụng quản lý tài chính cá nhân trên iOS 26 (chỉ hỗ trợ iOS 26 trở lên), hỗ trợ theo dõi thu chi, quản lý nhiều tài khoản, lập ngân sách, phân tích chi tiêu, và theo dõi tài sản vàng. Ứng dụng hoạt động theo mô hình client-server: iOS app là client, giao tiếp với một backend REST API.

## Tech Stack

- **Platform**: iOS (SwiftUI)
- **Architecture**: MVVM (Model–View–ViewModel)
- **State Management**: `@ObservableObject` / `@MainActor` ViewModels, truyền qua `@EnvironmentObject`
- **Networking**: `URLSession` async/await
- **Persistence local**: `UserDefaults` (base URL, gold price cache, theme preference)
- **Backend**: REST API tự host (mặc định `http://localhost:3001`)

## Cấu trúc Navigation

Ứng dụng dùng tab bar nổi (DSTabBar - liquid glass style) với 4 tab chính:

| Tab | Icon | Tên | Màn hình |
|-----|------|-----|----------|
| 0 | chart.bar.fill | Flow | Dashboard |
| 1 | list.bullet | History | Transactions |
| 2 | chart.pie.fill | Insight | Analytics |
| 3 | person.fill | Profile | Settings |

Nút **+** nổi ở giữa tab bar → mở modal Thêm giao dịch.

## Luồng khởi động ứng dụng

```
App Launch
  └─ ContentView
       └─ AppViewModel.loadInitData()
            └─ GET /api/init
                 ├─ transactions[]
                 ├─ categories[]
                 ├─ accounts[]
                 ├─ accountBalances{}
                 ├─ budgets[]
                 ├─ goldAssets[]
                 └─ settings{}
```

Toàn bộ dữ liệu được load một lần duy nhất khi khởi động. Sau đó mỗi thao tác CRUD sẽ gọi API riêng và cập nhật state trong `AppViewModel`.

## Tài liệu chi tiết

- [Màn hình & Tính năng](./screens.md)
- [Data Models](./data-models.md)
- [API Reference](./api-reference.md)
- [Business Logic](./business-logic.md)
- [State Management](./state-management.md)
