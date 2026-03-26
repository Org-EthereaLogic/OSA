import Foundation

/// Drives the trusted-source import flow presented from Ask
/// after insufficient local evidence.
///
/// All networking is user-initiated, allowlist-only, and preview-first.
/// Import uses the existing M4P4 pipeline — no duplicate persistence logic.
@MainActor
final class TrustedSourceImportViewModel: ObservableObject {

    // MARK: - Published State

    @Published var searchText = ""
    @Published var urlText = ""
    @Published private(set) var importState: ImportFlowState = .browsing
    @Published private(set) var previewTitle: String?
    @Published private(set) var previewDomain: String?
    @Published private(set) var previewExcerpt: String?
    @Published private(set) var errorMessage: String?

    // MARK: - Dependencies

    private let httpClient: any TrustedSourceHTTPClient
    private let importPipeline: ImportedKnowledgeImportPipeline
    let originalQuery: String

    private var fetchedResponse: TrustedSourceFetchResponse?

    // MARK: - Computed

    /// Approved-only publishers for the Ask-driven import path.
    var approvedSources: [TrustedSourceDefinition] {
        let sources = TrustedSourceAllowlist.allSources.filter {
            $0.defaultReviewStatus == .approved
        }
        guard !searchText.isEmpty else { return sources }
        let term = searchText.lowercased()
        return sources.filter {
            $0.publisherName.lowercased().contains(term) ||
            $0.canonicalHost.lowercased().contains(term) ||
            ($0.notes?.lowercased().contains(term) ?? false)
        }
    }

    /// Validates the current URL text against allowlist rules.
    var urlValidation: URLValidationResult {
        let trimmed = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .empty }
        guard let url = URL(string: trimmed) else { return .invalid("Not a valid URL.") }
        guard url.scheme?.lowercased() == "https" else { return .invalid("Only HTTPS URLs are supported.") }
        guard let host = url.host?.lowercased() else { return .invalid("URL has no host.") }
        guard let entry = TrustedSourceAllowlist.definition(forHost: host) else {
            return .invalid("Host \"\(host)\" is not an approved publisher.")
        }
        guard entry.defaultReviewStatus == .approved else {
            return .invalid("This publisher is pending review and cannot be imported from Ask.")
        }
        return .valid(url)
    }

    // MARK: - Init

    init(
        httpClient: any TrustedSourceHTTPClient,
        importPipeline: ImportedKnowledgeImportPipeline,
        originalQuery: String
    ) {
        self.httpClient = httpClient
        self.importPipeline = importPipeline
        self.originalQuery = originalQuery
    }

    // MARK: - Actions

    func prefillHost(_ host: String) {
        urlText = "https://\(host)/"
    }

    func fetchPreview() async {
        guard case .valid(let url) = urlValidation else { return }

        importState = .fetching
        errorMessage = nil

        do {
            let response = try await httpClient.fetch(url)
            let normalized = try ImportedKnowledgeNormalizer.normalize(response)

            fetchedResponse = response
            previewTitle = normalized.title
            previewDomain = normalized.publisherDomain
            previewExcerpt = String(normalized.plainText.prefix(300))
            importState = .previewing
        } catch let error as TrustedSourceFetchError {
            errorMessage = describeFetchError(error)
            importState = .failed
        } catch let error as NormalizationError {
            errorMessage = describeNormalizationError(error)
            importState = .failed
        } catch {
            errorMessage = error.localizedDescription
            importState = .failed
        }
    }

    func confirmImport() async {
        guard let response = fetchedResponse else { return }

        importState = .importing
        errorMessage = nil

        do {
            try importPipeline.importFetchedContent(response)
            importState = .succeeded
        } catch {
            errorMessage = "Import failed: \(error.localizedDescription)"
            importState = .failed
        }
    }

    func resetToSearch() {
        importState = .browsing
        errorMessage = nil
        fetchedResponse = nil
        previewTitle = nil
        previewDomain = nil
        previewExcerpt = nil
    }

    // MARK: - Error Descriptions

    private func describeFetchError(_ error: TrustedSourceFetchError) -> String {
        switch error {
        case .offline:
            "Device is offline. Connect to the internet and try again."
        case .invalidScheme:
            "Only HTTPS URLs are supported."
        case .disallowedHost:
            "This host is not an approved publisher."
        case .badStatusCode(let code):
            "The server returned an error (HTTP \(code))."
        case .unsupportedContentType(let type):
            "Unsupported content type: \(type ?? "unknown"). Only HTML and plain text are supported."
        case .oversizedPayload(let bytes):
            "Page is too large (\(bytes / 1024) KB). Maximum is 2 MB."
        case .redirectedToDisallowedHost(let host):
            "Redirected to unapproved host: \(host)."
        }
    }

    private func describeNormalizationError(_ error: NormalizationError) -> String {
        switch error {
        case .emptyContent:
            "No importable content found on this page."
        case .unsupportedContentType(let type):
            "Unsupported content type: \(type ?? "unknown")."
        case .decodingFailed:
            "Unable to decode the page content."
        }
    }
}

// MARK: - Supporting Types

enum ImportFlowState: Equatable {
    case browsing
    case fetching
    case previewing
    case importing
    case succeeded
    case failed
}

enum URLValidationResult: Equatable {
    case empty
    case valid(URL)
    case invalid(String)

    var isValid: Bool {
        if case .valid = self { return true }
        return false
    }
}
