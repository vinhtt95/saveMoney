import Foundation
import SwiftUI

@Observable
@MainActor
final class AccountViewModel {
    // MARK: - State Properties
    var isSubmitting = false
    var errorMessage: String?
    var showSuccessAlert = false
    
    private let app: AppViewModel
    
    // MARK: - Initialization
    init(app: AppViewModel) {
        self.app = app
    }
    
    // MARK: - Validation
    private func validate(name: String) -> Bool {
        if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            self.errorMessage = "Tên tài khoản không được để trống." // Account name cannot be empty
            return false
        }
        return true
    }
    
    // MARK: - Intentions (Actions)
    
    /// Thêm tài khoản mới / Add a new account
    func addAccount(name: String, initialBalance: Double?, icon: String, color: String, onSuccess: (() -> Void)? = nil) async {
        guard validate(name: name) else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        // Chuẩn hóa dữ liệu / Normalize data
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let dto = AccountCreateDTO(
            name: cleanName,
            initialBalance: initialBalance ?? 0.0,
            icon: icon,
            color: color
        )
        
        do {
            try await app.addAccount(dto)
            self.showSuccessAlert = true
            onSuccess?()
            // Lưu ý: Nếu app.addAccount làm thay đổi tổng số dư, AppViewModel nên gọi WidgetDataManager.shared.updateWidgetData(...) ở đó.
            // Note: If app.addAccount changes the total balance, AppViewModel should call WidgetDataManager.shared.updateWidgetData(...) there.
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    /// Cập nhật tài khoản / Update an existing account
    func updateAccount(id: String, name: String, balance: Double?, icon: String, color: String, onSuccess: (() -> Void)? = nil) async {
        guard validate(name: name) else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let cleanName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let dto = AccountUpdateDTO(
            name: cleanName,
            balance: balance,
            icon: icon,
            color: color
        )
        
        do {
            try await app.updateAccount(id, dto)
            self.showSuccessAlert = true
            onSuccess?()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    /// Xóa tài khoản / Delete an account
    func deleteAccount(_ id: String, onSuccess: (() -> Void)? = nil) async {
        isSubmitting = true
        errorMessage = nil
        
        do {
            try await app.deleteAccount(id)
            onSuccess?()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isSubmitting = false
    }
    
    /// Xóa thông báo lỗi / Clear error message
    func clearError() {
        self.errorMessage = nil
    }
}
