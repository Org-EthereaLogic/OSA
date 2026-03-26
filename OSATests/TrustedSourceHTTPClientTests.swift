import Foundation
import Testing
@testable import OSA

// MARK: - Stub Infrastructure

/// A controllable `ConnectivityService` for tests.
private final class StubConnectivityService: ConnectivityService, @unchecked Sendable {
    @MainActor var currentState: ConnectivityState = .onlineUsable

    @MainActor func stateStream() -> AsyncStream<ConnectivityState> {
        AsyncStream { $0.yield(self.currentState); $0.finish() }
    }

    func start() {}
    func stop() {}
    @MainActor func setSyncInProgress() {}
    @MainActor func clearSyncInProgress() {}
}

/// A `URLProtocol` subclass that returns preconfigured responses.
private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseProvider: ((URLRequest) -> (Data, HTTPURLResponse))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let provider = Self.responseProvider,
              request.url != nil else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let (data, response) = provider(request)
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

/// Builds a stubbed `URLSession` + client pair for testing.
private func makeTestClient(
    connectivity: StubConnectivityService = StubConnectivityService()
) -> (URLSessionTrustedSourceHTTPClient, StubConnectivityService) {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StubURLProtocol.self]
    let session = URLSession(configuration: config)
    let client = URLSessionTrustedSourceHTTPClient(
        session: session,
        connectivityService: connectivity
    )
    return (client, connectivity)
}

/// Configures StubURLProtocol to return a fixed response.
private func stubResponse(
    url: URL,
    statusCode: Int = 200,
    mimeType: String = "text/html",
    body: Data = Data("<html></html>".utf8),
    finalURL: URL? = nil
) {
    StubURLProtocol.responseProvider = { _ in
        let responseURL = finalURL ?? url
        let response = HTTPURLResponse(
            url: responseURL,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": mimeType]
        )!
        return (body, response)
    }
}

// MARK: - Tests

@Suite("TrustedSourceHTTPClient", .serialized)
struct TrustedSourceHTTPClientTests {

    // MARK: - Success

    @Test("Fetch succeeds for approved HTTPS host with supported content type")
    func fetchSucceeds() async throws {
        let url = URL(string: "https://www.ready.gov/plan")!
        stubResponse(url: url)
        let (client, _) = makeTestClient()

        let result = try await client.fetch(url)
        #expect(result.requestedURL == url)
        #expect(result.httpStatusCode == 200)
        #expect(result.contentType == "text/html")
        #expect(result.body.isEmpty == false)
    }

    // MARK: - Offline

    @Test("Fetch fails when device is offline")
    func offlineFails() async {
        let url = URL(string: "https://www.ready.gov/plan")!
        stubResponse(url: url)
        let connectivity = StubConnectivityService()
        await MainActor.run { connectivity.currentState = .offline }
        let (client, _) = makeTestClient(connectivity: connectivity)

        await #expect(throws: TrustedSourceFetchError.offline) {
            try await client.fetch(url)
        }
    }

    // MARK: - Non-HTTPS

    @Test("Fetch fails for non-HTTPS URL")
    func nonHTTPSFails() async {
        let url = URL(string: "http://www.ready.gov/plan")!
        let (client, _) = makeTestClient()

        await #expect(throws: TrustedSourceFetchError.invalidScheme) {
            try await client.fetch(url)
        }
    }

    // MARK: - Unknown Host

    @Test("Fetch fails for unknown host")
    func unknownHostFails() async {
        let url = URL(string: "https://example.com/page")!
        let (client, _) = makeTestClient()

        await #expect(throws: TrustedSourceFetchError.disallowedHost) {
            try await client.fetch(url)
        }
    }

    // MARK: - Bad Status Code

    @Test("Fetch fails for non-2xx status code")
    func badStatusCodeFails() async {
        let url = URL(string: "https://www.ready.gov/missing")!
        stubResponse(url: url, statusCode: 404)
        let (client, _) = makeTestClient()

        await #expect(throws: TrustedSourceFetchError.badStatusCode(404)) {
            try await client.fetch(url)
        }
    }

    // MARK: - Unsupported Content Type

    @Test("Fetch fails for unsupported content type")
    func unsupportedContentTypeFails() async {
        let url = URL(string: "https://www.ready.gov/doc.pdf")!
        stubResponse(url: url, mimeType: "application/pdf")
        let (client, _) = makeTestClient()

        await #expect(throws: TrustedSourceFetchError.unsupportedContentType("application/pdf")) {
            try await client.fetch(url)
        }
    }

    // MARK: - Oversized Payload

    @Test("Fetch fails for oversized payload")
    func oversizedPayloadFails() async {
        let url = URL(string: "https://www.ready.gov/large")!
        let oversizedData = Data(repeating: 0x41, count: URLSessionTrustedSourceHTTPClient.maxPayloadBytes + 1)
        stubResponse(url: url, body: oversizedData)
        let (client, _) = makeTestClient()

        await #expect {
            try await client.fetch(url)
        } throws: { error in
            guard let fetchError = error as? TrustedSourceFetchError,
                  case .oversizedPayload = fetchError else {
                return false
            }
            return true
        }
    }

    // MARK: - Redirect to Unapproved Host

    @Test("Fetch fails when redirect lands on unapproved host")
    func redirectToDisallowedHostFails() async {
        let url = URL(string: "https://www.ready.gov/redirect")!
        let evilURL = URL(string: "https://evil.example.com/page")!
        stubResponse(url: url, finalURL: evilURL)
        let (client, _) = makeTestClient()

        await #expect {
            try await client.fetch(url)
        } throws: { error in
            guard let fetchError = error as? TrustedSourceFetchError,
                  case .redirectedToDisallowedHost = fetchError else {
                return false
            }
            return true
        }
    }

    // MARK: - Redirect to Approved Host

    @Test("Fetch succeeds when redirect stays within approved hosts")
    func redirectToApprovedHostSucceeds() async throws {
        let url = URL(string: "https://www.ready.gov/old-page")!
        let newURL = URL(string: "https://www.usgs.gov/new-page")!
        stubResponse(url: url, finalURL: newURL)
        let (client, _) = makeTestClient()

        let result = try await client.fetch(url)
        #expect(result.requestedURL == url)
        #expect(result.finalURL == newURL)
    }

    // MARK: - text/plain Content Type

    @Test("Fetch succeeds for text/plain content type")
    func textPlainSucceeds() async throws {
        let url = URL(string: "https://pnsn.org/data.txt")!
        stubResponse(url: url, mimeType: "text/plain", body: Data("hello".utf8))
        let (client, _) = makeTestClient()

        let result = try await client.fetch(url)
        #expect(result.contentType == "text/plain")
    }
}
