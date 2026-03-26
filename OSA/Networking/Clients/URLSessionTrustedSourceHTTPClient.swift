import Foundation

/// Live ``TrustedSourceHTTPClient`` backed by a foreground `URLSession`.
///
/// Guards enforced before and after the network request:
/// 1. Device must be online (via ``ConnectivityService``).
/// 2. URL scheme must be `https`.
/// 3. URL host must be in ``TrustedSourceAllowlist``.
/// 4. HTTP status code must be 2xx.
/// 5. Content-Type must be a supported text format.
/// 6. Response body must not exceed ``maxPayloadBytes``.
/// 7. The final (post-redirect) URL host must still be allowlisted.
final class URLSessionTrustedSourceHTTPClient: TrustedSourceHTTPClient {

    /// Text-oriented MIME types accepted in M4P3.
    private static let supportedContentTypes: Set<String> = [
        "text/html",
        "text/plain",
        "application/xhtml+xml",
    ]

    /// Maximum payload size for the first text-source prototype (2 MB).
    static let maxPayloadBytes = 2 * 1_024 * 1_024

    private let session: URLSession
    private let connectivityService: any ConnectivityService

    init(session: URLSession = .shared,
         connectivityService: any ConnectivityService) {
        self.session = session
        self.connectivityService = connectivityService
    }

    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse {
        // 1. Check connectivity
        let state = await MainActor.run { connectivityService.currentState }
        guard state == .onlineUsable || state == .onlineConstrained else {
            throw TrustedSourceFetchError.offline
        }

        // 2. Require HTTPS
        guard url.scheme?.lowercased() == "https" else {
            throw TrustedSourceFetchError.invalidScheme
        }

        // 3. Require allowlisted host
        guard TrustedSourceAllowlist.isAllowed(url) else {
            throw TrustedSourceFetchError.disallowedHost
        }

        // 4. Perform the request
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TrustedSourceFetchError.badStatusCode(0)
        }

        // 5. Validate the final URL host after redirects
        if let finalURL = httpResponse.url,
           finalURL.host?.lowercased() != url.host?.lowercased() {
            guard TrustedSourceAllowlist.isAllowed(finalURL) else {
                let host = finalURL.host ?? "unknown"
                throw TrustedSourceFetchError.redirectedToDisallowedHost(host)
            }
        }

        // 6. Validate HTTP status
        guard (200...299).contains(httpResponse.statusCode) else {
            throw TrustedSourceFetchError.badStatusCode(httpResponse.statusCode)
        }

        // 7. Validate content type
        let mimeType = httpResponse.mimeType?.lowercased()
        guard let mime = mimeType,
              Self.supportedContentTypes.contains(mime) else {
            throw TrustedSourceFetchError.unsupportedContentType(mimeType)
        }

        // 8. Validate payload size
        guard data.count <= Self.maxPayloadBytes else {
            throw TrustedSourceFetchError.oversizedPayload(bytes: data.count)
        }

        return TrustedSourceFetchResponse(
            requestedURL: url,
            finalURL: httpResponse.url ?? url,
            httpStatusCode: httpResponse.statusCode,
            contentType: mimeType,
            body: data,
            fetchedAt: Date()
        )
    }
}
