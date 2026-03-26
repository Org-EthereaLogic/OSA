import Foundation

/// Errors raised by ``TrustedSourceHTTPClient`` implementations.
enum TrustedSourceFetchError: Error, Equatable {
    /// The device is currently offline.
    case offline

    /// The URL scheme is not HTTPS.
    case invalidScheme

    /// The URL's host is not in the trusted-source allowlist.
    case disallowedHost

    /// The server returned a non-success HTTP status code.
    case badStatusCode(Int)

    /// The response Content-Type is not a supported text format.
    case unsupportedContentType(String?)

    /// The response body exceeds the maximum allowed size.
    case oversizedPayload(bytes: Int)

    /// A redirect resolved to a host not in the trusted-source allowlist.
    case redirectedToDisallowedHost(String)
}

/// A client that fetches raw content only from trusted, HTTPS-only sources.
///
/// Implementations must verify connectivity, URL scheme, allowlist membership,
/// response status, content type, payload size, and post-redirect host before
/// returning a ``TrustedSourceFetchResponse``.
protocol TrustedSourceHTTPClient: Sendable {
    func fetch(_ url: URL) async throws -> TrustedSourceFetchResponse
}
