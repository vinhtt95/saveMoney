import Foundation

enum Constants {
    static let defaultBaseURL = "http://localhost:3001"
    static let goldCacheTTL: TimeInterval = 300 // 5 minutes
    static let pageSize = 20
    static let dashboardRecentCount = 10
    static let apiBaseURLKey = "api_base_url"
    static let goldPriceCacheKey = "gold_price_cache"
    static let themePreferenceKey = "theme_preference"
    // Thêm App Group ID chuẩn của bạn vào đây
    static let appGroup = "group.com.vinhtt.savemoney"
    
    // Gold conversion: 1 tael (lượng) = 37.5g = 1.2057 troy oz
    static let taelToGrams: Double = 37.5
    static let taelToTroyOz: Double = 1.2057
}

enum SettingsKey {
    static let defaultTransactionType = "default_transaction_type"
    static let defaultAccountId = "default_account_id"
    static let defaultExpenseCategoryId = "default_expense_category_id"
    static let defaultIncomeCategoryId = "default_income_category_id"
}

enum AppIcons {
    static let allIcons = [
        // --- NHÓM TÀI CHÍNH & QUẢN LÝ (Cho Accounts) ---
        "creditcard.fill", "banknote.fill", "building.columns.fill", "wallet.pass.fill",
        "dollarsign.circle.fill", "bitcoinsign.circle.fill", "eurosign.circle.fill",
        "yensign.circle.fill", "chart.pie.fill", "briefcase.fill", "lock.fill",
        "archivebox.fill", "tray.fill", "signature", "bag.fill", "cart.fill",

        // --- ĐỜI SỐNG & CHI TIÊU (Cho Categories) ---
        "fork.knife", "cup.and.saucer.fill", "wineglass.fill", "takeoutbag.and.cup.and.straw.fill",
        "car.fill", "bus.fill", "tram.fill", "airplane", "fuelpump.fill",
        "house.fill", "lightbulb.fill", "drop.fill", "bolt.fill", "shower.fill",
        "tshirt.fill", "pawprint.fill", "scissors", "tag.fill", "gift.fill",

        // --- SỨC KHỎE & THỂ THAO ---
        "heart.fill", "pills.fill", "cross.case.fill", "stethoscope",
        "figure.run", "figure.walk", "figure.outdoor.cycle", "dumbbell.fill",

        // --- CÔNG VIỆC & GIÁO DỤC ---
        "book.fill", "graduationcap.fill", "pencil.tip", "hammer.fill",
        "wrench.and.screwdriver.fill", "folder.fill", "paperclip",

        // --- GIẢI TRÍ & TIỆN ÍCH ---
        "gamecontroller.fill", "tv.fill", "music.note", "camera.fill",
        "theatermasks.fill", "popcorn.fill", "mic.fill", "phone.fill",
        "envelope.fill", "map.fill", "location.fill", "bell.fill",

        // --- HỆ THỐNG (Giống Reminders) ---
        "star.fill", "flag.fill", "bookmark.fill", "sun.max.fill", "moon.fill",
        "cloud.fill", "umbrella.fill", "leaf.fill"
    ]
}
