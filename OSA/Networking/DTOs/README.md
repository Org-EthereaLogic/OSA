# DTOs

Network-facing payloads, parser inputs, and remote metadata transfer objects.

## M4P3: TrustedSourceFetchResponse

- `TrustedSourceFetchResponse`: Raw result of a successful HTTP fetch from an allowlisted source. Carries requested URL, final URL (post-redirect), HTTP status code, MIME type, raw response body, and fetch timestamp. Does not claim content approval, chunking, or persistence; those responsibilities belong to later import-pipeline stages (M4P4+).
