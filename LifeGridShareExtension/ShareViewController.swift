import Social
import UniformTypeIdentifiers

final class ShareViewController: SLComposeServiceViewController {
    private let draftStore = AppGroupSharedReflectionDraftStore()

    override func isContentValid() -> Bool {
        let typedText = contentText?.trimmingCharacters(in: .whitespacesAndNewlines)
        return !(typedText?.isEmpty ?? true) || hasSupportedAttachment
    }

    override func didSelectPost() {
        Task { @MainActor in
            do {
                let text = try await receivedText()
                try draftStore.append(
                    SharedReflectionDraft(suggestedText: text)
                )
                extensionContext?.completeRequest(returningItems: nil)
            } catch {
                extensionContext?.cancelRequest(withError: error)
            }
        }
    }

    override func didSelectCancel() {
        extensionContext?.cancelRequest(
            withError: ShareReflectionError.cancelledByUser
        )
    }

    override func configurationItems() -> [Any]! {
        []
    }

    private var hasSupportedAttachment: Bool {
        inputProviders.contains { provider in
            provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier)
                || provider.hasItemConformingToTypeIdentifier(UTType.url.identifier)
        }
    }

    private var inputProviders: [NSItemProvider] {
        (extensionContext?.inputItems as? [NSExtensionItem] ?? [])
            .flatMap { $0.attachments ?? [] }
    }

    private func receivedText() async throws -> String {
        var fragments: [String] = []

        if let typedText = contentText?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !typedText.isEmpty {
            fragments.append(typedText)
        }

        for provider in inputProviders {
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier),
               let text = try? await loadString(
                    from: provider
               ),
               !text.isEmpty,
               !fragments.contains(text) {
                fragments.append(text)
            } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier),
                      let url = try? await loadURL(from: provider) {
                fragments.append(url.absoluteString)
            }
        }

        let combined = fragments.joined(separator: "\n\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !combined.isEmpty else {
            throw ShareReflectionError.noSupportedContent
        }

        return combined
    }

    private func loadString(from provider: NSItemProvider) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadObject(ofClass: NSString.self) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let text = item as? String {
                    continuation.resume(
                        returning: text.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                } else {
                    continuation.resume(throwing: ShareReflectionError.noSupportedContent)
                }
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadObject(ofClass: NSURL.self) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = item as? URL {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(throwing: ShareReflectionError.noSupportedContent)
                }
            }
        }
    }
}

enum ShareReflectionError: Error {
    case noSupportedContent
    case cancelledByUser
}
