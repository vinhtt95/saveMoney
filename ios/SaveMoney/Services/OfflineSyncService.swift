import Foundation

@MainActor
final class OfflineSyncService {
    private let api: APIService
    private let store: LocalDataStore
    private(set) var isSyncing = false

    /// Called after sync completes so AppViewModel can reload fresh data
    var onSyncCompleted: (() async -> Void)?

    init(api: APIService, store: LocalDataStore) {
        self.api = api
        self.store = store
    }

    func syncPending() async {
        guard !isSyncing else { return }
        isSyncing = true
        defer { isSyncing = false }

        let ops = store.fetchPendingOps()
        guard !ops.isEmpty else {
            await onSyncCompleted?()
            return
        }

        print("🔄 OfflineSync: processing \(ops.count) pending operations")

        for op in ops {
            do {
                switch op.operationType {
                case "create":
                    try await syncCreate(op)
                case "update":
                    try await syncUpdate(op)
                case "delete":
                    try await syncDelete(op)
                default:
                    store.dequeueSyncOp(op)
                }
            } catch APIError.httpError(let statusCode, let message) where statusCode >= 400 && statusCode < 500 {
                // 4xx = bad request / invalid data — retrying won't help, discard the op
                print("🗑️ OfflineSync: discarding invalid op \(op.operationType) for \(op.entityId) — server rejected with \(statusCode): \(message)")
                store.dequeueSyncOp(op)
            } catch {
                print("❌ OfflineSync: failed op \(op.operationType) for \(op.entityId): \(error)")
                store.incrementRetry(op)
                // Skip this op and continue with others
            }
        }

        print("✅ OfflineSync: done, reloading data from server")
        await onSyncCompleted?()
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

        // Update local record: replace temp ID with real server ID
        store.updateTransactionId(from: tempId, to: created.id)
        // Also persist the full server-returned transaction
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
