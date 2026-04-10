import Foundation

enum APIError: LocalizedError {
    case httpError(Int, String)
    case networkError(Error)
    case decodingError(Error)
    case invalidURL

    var errorDescription: String? {
        switch self {
        case .httpError(let code, let message): "Lỗi \(code): \(message)"
        case .networkError(let error): "Lỗi mạng: \(error.localizedDescription)"
        case .decodingError(let error): "Lỗi dữ liệu: \(error.localizedDescription)"
        case .invalidURL: "URL không hợp lệ"
        }
    }
}

@Observable
@MainActor
final class APIService {
    var baseURL: String {
        get {
            let stored = UserDefaults.standard.string(forKey: Constants.apiBaseURLKey) ?? Constants.defaultBaseURL
            return normalizeURL(stored)
        }
        set { UserDefaults.standard.set(newValue, forKey: Constants.apiBaseURLKey) }
    }

    private func normalizeURL(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        return "http://\(trimmed)"
    }

    // MARK: - Generic Request
    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        let fullURL = "\(baseURL)\(path)"
        print("🔵 API Request: \(method) \(fullURL)")

        guard let url = URL(string: fullURL) else {
            print("❌ Invalid URL: \(fullURL)")
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            print("✅ Response: \(response)")

            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ HTTP Error \(http.statusCode): \(msg)")
                throw APIError.httpError(http.statusCode, msg)
            }
            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                print("❌ Decoding Error: \(error)")
                throw APIError.decodingError(error)
            }
        } catch let error as APIError {
            throw error
        } catch {
            print("❌ Network Error: \(error.localizedDescription)")
            throw APIError.networkError(error)
        }
    }

    private func requestVoid(_ path: String, method: String, body: (any Encodable)? = nil) async throws {
        guard let url = URL(string: "\(baseURL)\(path)") else { throw APIError.invalidURL }
        var req = URLRequest(url: url, timeoutInterval: 30)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { req.httpBody = try JSONEncoder().encode(body) }
        do {
            let (data, response) = try await URLSession.shared.data(for: req)
            if let http = response as? HTTPURLResponse, http.statusCode >= 400 {
                let msg = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw APIError.httpError(http.statusCode, msg)
            }
        } catch let error as APIError {
            throw error
        } catch {
            throw APIError.networkError(error)
        }
    }

    // MARK: - Init
    func fetchInit() async throws -> AppInitData {
        try await request("/api/init")
    }

    // MARK: - Transactions
    func createTransaction(_ dto: TransactionCreateDTO) async throws -> Transaction {
        try await request("/api/transactions", method: "POST", body: dto)
    }

    func updateTransaction(_ id: String, _ dto: TransactionCreateDTO) async throws -> Transaction {
        try await request("/api/transactions/\(id)", method: "PUT", body: dto)
    }

    func deleteTransaction(_ id: String) async throws {
        try await requestVoid("/api/transactions/\(id)", method: "DELETE")
    }

    // MARK: - Accounts
    func createAccount(_ dto: AccountCreateDTO) async throws -> Account {
        try await request("/api/accounts", method: "POST", body: dto)
    }

    func updateAccount(_ id: String, _ dto: AccountUpdateDTO) async throws -> Account {
        try await request("/api/accounts/\(id)", method: "PUT", body: dto)
    }

    func deleteAccount(_ id: String) async throws {
        try await requestVoid("/api/accounts/\(id)", method: "DELETE")
    }

    // MARK: - Categories
    func createCategory(_ dto: CategoryCreateDTO) async throws -> Category {
        try await request("/api/categories", method: "POST", body: dto)
    }

    func updateCategory(_ id: String, _ dto: CategoryUpdateDTO) async throws -> Category {
        try await request("/api/categories/\(id)", method: "PUT", body: dto)
    }

    func deleteCategory(_ id: String) async throws {
        try await requestVoid("/api/categories/\(id)", method: "DELETE")
    }

    // MARK: - Budgets
    func createBudget(_ dto: BudgetCreateDTO) async throws -> Budget {
        try await request("/api/budgets", method: "POST", body: dto)
    }
    
    func updateBudget(_ id: String, _ dto: BudgetCreateDTO) async throws -> Budget {
        try await request("/api/budgets/\(id)", method: "PUT", body: dto)
    }

    func deleteBudget(_ id: String) async throws {
        try await requestVoid("/api/budgets/\(id)", method: "DELETE")
    }

    // MARK: - Gold
    func fetchGoldPrices() async throws -> GoldPricesResponse {
        try await request("/api/gold-prices")
    }

    func createGoldAsset(_ dto: GoldAssetCreateDTO) async throws -> GoldAsset {
        try await request("/api/gold-assets", method: "POST", body: dto)
    }

    func deleteGoldAsset(_ id: String) async throws {
        try await requestVoid("/api/gold-assets/\(id)", method: "DELETE")
    }

    // MARK: - Settings
    func getSettings() async throws -> [String: String] {
        try await request("/api/settings")
    }

    func updateSettings(_ dict: [String: String]) async throws {
        try await requestVoid("/api/settings", method: "PUT", body: dict)
    }
}
