# Clients

Trusted-source discovery, allowlist enforcement, and HTTP client implementations.

## M4P1: ConnectivityService

- `NWPathMonitorConnectivityService`: Live implementation wrapping `NWPathMonitor`, publishes `ConnectivityState` reactively.
- `PreviewConnectivityService`: Preview/test stub for SwiftUI previews.

## M4P3: Trusted-Source Allowlist And HTTP Client

- `TrustedSourceAllowlist`: Static allowlist of 15 PNW-focused launch publishers across three trust tiers (curated/approved, community/approved, unverified/pending). Exact host matching only, no wildcards. Maps onto existing `TrustLevel` and `ReviewStatus` domain enums.
- `TrustedSourceHTTPClient`: Protocol defining the fetch contract for approved sources. Includes `TrustedSourceFetchError` covering offline, invalid scheme, disallowed host, bad status, unsupported content type, oversized payload, and redirect-to-disallowed-host cases.
- `URLSessionTrustedSourceHTTPClient`: Live `URLSession`-backed implementation enforcing connectivity check, HTTPS scheme, pre-request allowlist, HTTP 2xx status, post-redirect allowlist, text-only Content-Type, and 2 MB payload size limit.
