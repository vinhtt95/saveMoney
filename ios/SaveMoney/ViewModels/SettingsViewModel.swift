import Foundation

@MainActor
class SettingsViewModel: ObservableObject {
    @Published var baseURL: String = APIService.shared.baseURL
    @Published var isSaving = false
    @Published var saveError: String?
    @Published var saveSuccess = false

    private let api = APIService.shared

    func saveBaseURL() {
        api.baseURL = baseURL
    }

    func saveDefaults(settings: [String: String], appVM: AppViewModel) async {
        isSaving = true
        saveError = nil
        saveSuccess = false
        do {
            let updated = try await api.updateSettings(settings)
            appVM.settings = updated
            saveSuccess = true
        } catch {
            saveError = error.localizedDescription
        }
        isSaving = false
    }
}
