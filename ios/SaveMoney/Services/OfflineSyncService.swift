import Foundation

@MainActor
final class OfflineSyncService {
    private let api: APIService
    private let store: LocalDataStore
    private(set) var isSyncing = false

    /// Theo dõi số lần thử lại trong phiên mở app hiện tại (Lưu trên RAM)
    private var sessionRetries: [UUID: Int] = [:]

    var onSyncHalted: (() -> Void)? // Gọi khi chạm mốc 3 lần lỗi

    init(api: APIService, store: LocalDataStore) {
        self.api = api
        self.store = store
    }
    
    /// Gọi khi user mở lại app (re-open) để reset bộ đếm
    func resetSession() {
        sessionRetries.removeAll()
    }

    func syncPending(isOnline: Bool) async {
        guard isOnline else { return }
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }
        
        let ops = store.fetchPendingOps()
        
        // Trả về luôn nếu không có gì cần đồng bộ (Không gọi callback nữa)
        guard !ops.isEmpty else { return }
        
        print("🔄 OfflineSync: processing \(ops.count) pending operations")
        
        for op in ops {
            do {
                switch op.operationType {
                case "create": try await syncCreate(op)
                case "update": try await syncUpdate(op)
                case "delete": try await syncDelete(op)
                default: store.dequeueSyncOp(op)
                }
                sessionRetries.removeValue(forKey: op.id)
                
            } catch APIError.httpError(let statusCode, let message) where statusCode >= 400 && statusCode < 500 {
                print("🗑️ OfflineSync: discarding invalid op \(op.operationType) for \(op.entityId) — server rejected with \(statusCode): \(message)")
                store.dequeueSyncOp(op)
                sessionRetries.removeValue(forKey: op.id)
                
            } catch {
                let currentRetries = sessionRetries[op.id, default: 0] + 1
                sessionRetries[op.id] = currentRetries
                
                print("❌ OfflineSync: failed op for \(op.entityId). Session retry count: \(currentRetries)/3")
                
                if currentRetries >= 3 {
                    print("⚠️ OfflineSync: Max retries (3) reached. Halting queue.")
                    onSyncHalted?()
                    return
                }
                return
            }
        }
        print("✅ OfflineSync: done")
    }
    
    private func syncCreate(_ op: PendingSyncOperation) async throws {
        guard let payloadData = op.payload,
              let dto = try? JSONDecoder().decode(TransactionCreateDTO.self, from: payloadData)
        else {
            store.dequeueSyncOp(op)
            return
        }

        let tempId = op.entityId
        let created = try await api.createTransaction(dto)

        store.updateTransactionId(from: tempId, to: created.id)
        store.updatePendingOpsId(from: tempId, to: created.id)
        store.upsertTransaction(created)

        store.dequeueSyncOp(op)
        print("✅ OfflineSync: created transaction \(tempId) → \(created.id)")
    }

    private func syncUpdate(_ op: PendingSyncOperation) async throws {
        guard let payloadData = op.payload,
              let dto = try? JSONDecoder().decode(TransactionCreateDTO.self, from: payloadData)
        else {
            store.dequeueSyncOp(op)
            return
        }

        let updated = try await api.updateTransaction(op.entityId, dto)
        store.upsertTransaction(updated)
        store.dequeueSyncOp(op)
        print("✅ OfflineSync: updated transaction \(op.entityId)")
    }

    private func syncDelete(_ op: PendingSyncOperation) async throws {
        try await api.deleteTransaction(op.entityId)
        store.dequeueSyncOp(op)
        print("✅ OfflineSync: deleted transaction \(op.entityId)")
    }
}
