import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case httpError(Int)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL không hợp lệ"
        case .httpError(let code): return "Lỗi HTTP \(code)"
        case .decodingError(let e): return "Lỗi parse dữ liệu: \(e.localizedDescription)"
        case .networkError(let e): return "Lỗi mạng: \(e.localizedDescription)"
        }
    }
}

class APIService {
    static let shared = APIService()

    var baseURL: String {
        get { UserDefaults.standard.string(forKey: "base_url") ?? "http://localhost:3001" }
        set { UserDefaults.standard.set(newValue, forKey: "base_url") }
    }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    // MARK: - Generic Request

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            req.httpBody = try encoder.encode(body)
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    func requestVoid(_ path: String, method: String = "DELETE") async throws {
        guard let url = URL(string: baseURL + path) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = method
        let (_, response) = try await session.data(for: req)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.httpError(http.statusCode)
        }
    }

    // MARK: - Init

    func getInitData() async throws -> AppInitData {
        try await request("/api/init")
    }

    // MARK: - Transactions

    func getTransactions() async throws -> [Transaction] {
        try await request("/api/transactions")
    }

    func createTransaction(_ body: CreateTransactionRequest) async throws -> Transaction {
        try await request("/api/transactions", method: "POST", body: body)
    }

    func updateTransaction(id: String, body: UpdateTransactionRequest) async throws -> Transaction {
        try await request("/api/transactions/\(id)", method: "PUT", body: body)
    }

    func deleteTransaction(id: String) async throws {
        try await requestVoid("/api/transactions/\(id)")
    }

    // MARK: - Categories

    func getCategories() async throws -> [Category] {
        try await request("/api/categories")
    }

    func createCategory(_ body: CreateCategoryRequest) async throws -> Category {
        try await request("/api/categories", method: "POST", body: body)
    }

    func deleteCategory(id: String) async throws {
        try await requestVoid("/api/categories/\(id)")
    }

    // MARK: - Accounts

    func getAccounts() async throws -> [Account] {
        try await request("/api/accounts")
    }

    func createAccount(_ body: CreateAccountRequest) async throws -> Account {
        try await request("/api/accounts", method: "POST", body: body)
    }

    func updateAccount(id: String, body: UpdateAccountRequest) async throws -> Account {
        try await request("/api/accounts/\(id)", method: "PUT", body: body)
    }

    func deleteAccount(id: String) async throws {
        try await requestVoid("/api/accounts/\(id)")
    }

    // MARK: - Budgets

    func getBudgets() async throws -> [Budget] {
        try await request("/api/budgets")
    }

    func createBudget(_ body: CreateBudgetRequest) async throws -> Budget {
        try await request("/api/budgets", method: "POST", body: body)
    }

    func deleteBudget(id: String) async throws {
        try await requestVoid("/api/budgets/\(id)")
    }

    // MARK: - Gold Prices

    func getGoldPrices() async throws -> GoldPricesResponse {
        try await request("/api/gold-prices")
    }

    // MARK: - Gold Assets

    func getGoldAssets() async throws -> [GoldAsset] {
        try await request("/api/gold-assets")
    }

    func createGoldAsset(_ body: CreateGoldAssetRequest) async throws -> GoldAsset {
        try await request("/api/gold-assets", method: "POST", body: body)
    }

    func deleteGoldAsset(id: String) async throws {
        try await requestVoid("/api/gold-assets/\(id)")
    }

    // MARK: - Settings

    func getSettings() async throws -> [String: String] {
        try await request("/api/settings")
    }

    func updateSettings(_ body: [String: String]) async throws -> [String: String] {
        try await request("/api/settings", method: "POST", body: body)
    }
}
