import Foundation
import Testing
@testable import OSA

@Suite("ImportedKnowledgeNormalizer")
struct ImportedKnowledgeNormalizerTests {

    private func makeResponse(
        body: String,
        contentType: String = "text/html",
        url: URL = URL(string: "https://www.ready.gov/water")!
    ) -> TrustedSourceFetchResponse {
        TrustedSourceFetchResponse(
            requestedURL: url,
            finalURL: url,
            httpStatusCode: 200,
            contentType: contentType,
            body: Data(body.utf8),
            fetchedAt: Date()
        )
    }

    // MARK: - HTML Normalization

    @Test("HTML normalization produces readable title and body text")
    func htmlNormalization() throws {
        let html = """
        <html><head><title>Water Storage Guide</title></head>
        <body><h1>Water Storage</h1><p>Store one gallon per person per day.</p>
        <p>Keep water in a cool, dark place.</p></body></html>
        """
        let response = makeResponse(body: html)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.title == "Water Storage Guide")
        #expect(doc.plainText.contains("gallon"))
        #expect(doc.plainText.contains("cool"))
        #expect(!doc.plainText.isEmpty)
        #expect(!doc.contentHash.isEmpty)
        #expect(doc.publisherDomain == "www.ready.gov")
        #expect(doc.sourceURL == "https://www.ready.gov/water")
    }

    @Test("HTML title falls back to h1 when no title tag")
    func htmlFallbackToH1() throws {
        let html = "<html><body><h1>Emergency Shelter</h1><p>Find safe shelter immediately.</p></body></html>"
        let response = makeResponse(body: html)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.title == "Emergency Shelter")
    }

    @Test("HTML title falls back to URL path when no title or h1")
    func htmlFallbackToURL() throws {
        let html = "<html><body><p>Some content about preparedness.</p></body></html>"
        let url = URL(string: "https://www.ready.gov/emergency-kit")!
        let response = makeResponse(body: html, url: url)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.title == "Emergency Kit")
    }

    // MARK: - Plain Text

    @Test("text/plain normalization preserves paragraphs")
    func plainTextNormalization() throws {
        let text = "First paragraph about water.\n\nSecond paragraph about storage.\n\nThird paragraph."
        let response = makeResponse(body: text, contentType: "text/plain")
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.plainText.contains("First paragraph"))
        #expect(doc.plainText.contains("Second paragraph"))
        #expect(doc.plainText.contains("\n\n"))
    }

    // MARK: - Empty Content

    @Test("Empty content fails deterministically")
    func emptyContentFails() {
        let response = makeResponse(body: "   \n\n  ")
        #expect(throws: NormalizationError.emptyContent) {
            try ImportedKnowledgeNormalizer.normalize(response)
        }
    }

    @Test("Empty HTML body fails")
    func emptyHTMLFails() {
        let html = "<html><head><title>Empty</title></head><body></body></html>"
        let response = makeResponse(body: html)
        #expect(throws: NormalizationError.emptyContent) {
            try ImportedKnowledgeNormalizer.normalize(response)
        }
    }

    // MARK: - Document Type

    @Test("Document type defaults to article")
    func defaultDocumentType() throws {
        let html = "<html><head><title>General Info</title></head><body><p>Some content.</p></body></html>"
        let response = makeResponse(body: html)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.documentType == .article)
    }

    @Test("Checklist title produces checklist type")
    func checklistDocumentType() throws {
        let html = "<html><head><title>Emergency Checklist</title></head><body><p>Items to pack.</p></body></html>"
        let response = makeResponse(body: html)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.documentType == .checklist)
    }

    @Test("Guide title produces guide type")
    func guideDocumentType() throws {
        let html = "<html><head><title>How to Build a Go Bag</title></head><body><p>Steps to build.</p></body></html>"
        let response = makeResponse(body: html)
        let doc = try ImportedKnowledgeNormalizer.normalize(response)

        #expect(doc.documentType == .guide)
    }

    // MARK: - Content Hash Stability

    @Test("Same normalized content produces same hash")
    func stableHash() throws {
        let html = "<html><head><title>Water</title></head><body><p>Store water safely.</p></body></html>"
        let r1 = makeResponse(body: html)
        let r2 = makeResponse(body: html)
        let doc1 = try ImportedKnowledgeNormalizer.normalize(r1)
        let doc2 = try ImportedKnowledgeNormalizer.normalize(r2)

        #expect(doc1.contentHash == doc2.contentHash)
    }

    // MARK: - Unsupported Content Type

    @Test("Unsupported content type fails")
    func unsupportedContentType() {
        let response = makeResponse(body: "binary data", contentType: "application/pdf")
        #expect(throws: NormalizationError.unsupportedContentType("application/pdf")) {
            try ImportedKnowledgeNormalizer.normalize(response)
        }
    }
}
