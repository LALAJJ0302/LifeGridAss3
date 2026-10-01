import Foundation

/// Main-app access to drafts created by the Share Extension.
protocol SharedReflectionDraftRepository: Sendable {
    func drafts() async throws -> [SharedReflectionDraft]
    func remove(id: SharedReflectionDraft.ID) async throws
}
