import Foundation

/// The raw result of a successful trusted-source HTTP fetch.
///
/// This DTO carries the unprocessed payload and metadata returned by
/// ``TrustedSourceHTTPClient``. It does not claim that the content has
/// been normalized, chunked, persisted, or approved for assistant use.
/// Those responsibilities belong to later import-pipeline stages.
struct TrustedSourceFetchResponse: Sendable {
    /// The URL that was originally requested.
    let requestedURL: URL

    /// The final URL after any server-side redirects.
    let finalURL: URL

    /// The HTTP status code of the response.
    let httpStatusCode: Int

    /// The MIME type or Content-Type header value, if provided.
    let contentType: String?

    /// The raw response body.
    let body: Data

    /// The moment the fetch completed.
    let fetchedAt: Date
}
