import Foundation

/// Parses NWS ATOM + CAP feeds into `WeatherAlert` values.
///
/// Handles both standard Atom `<entry>` elements and CAP-namespaced fields
/// (`cap:severity`, `cap:areaDesc`, `cap:effective`, `cap:expires`).
final class NWSAlertParser: NSObject, XMLParserDelegate, @unchecked Sendable {

    private var alerts: [WeatherAlert] = []
    private let feedHost: String

    // Parsing state
    private var currentElement = ""
    private var currentTitle = ""
    private var currentLink = ""
    private var currentSummary = ""
    private var currentSeverity = ""
    private var currentAreaDesc = ""
    private var currentEffective = ""
    private var currentExpires = ""
    private var insideEntry = false

    init(feedHost: String) {
        self.feedHost = feedHost
    }

    func parse(data: Data) -> [WeatherAlert] {
        alerts = []
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.parse()
        return alerts
    }

    // MARK: - XMLParserDelegate

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?,
        attributes attributeDict: [String: String]
    ) {
        let localName = elementName.contains(":") ? String(elementName.split(separator: ":").last ?? "") : elementName
        currentElement = elementName

        switch localName {
        case "entry":
            insideEntry = true
            currentTitle = ""
            currentLink = ""
            currentSummary = ""
            currentSeverity = ""
            currentAreaDesc = ""
            currentEffective = ""
            currentExpires = ""

        case "link" where insideEntry:
            if let href = attributeDict["href"] {
                let rel = attributeDict["rel"] ?? "alternate"
                if rel == "alternate" || currentLink.isEmpty {
                    currentLink = href
                }
            }

        case "item":
            insideEntry = true
            currentTitle = ""
            currentLink = ""
            currentSummary = ""
            currentSeverity = ""
            currentAreaDesc = ""
            currentEffective = ""
            currentExpires = ""

        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName: String?
    ) {
        let localName = elementName.contains(":") ? String(elementName.split(separator: ":").last ?? "") : elementName

        if localName == "entry" || localName == "item" {
            insideEntry = false
            let trimmedLink = currentLink.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedTitle = currentTitle.trimmingCharacters(in: .whitespacesAndNewlines)

            if let url = URL(string: trimmedLink), !trimmedTitle.isEmpty {
                let severity = mapSeverity(currentSeverity.trimmingCharacters(in: .whitespacesAndNewlines))
                let effective = Self.parseISO8601(currentEffective.trimmingCharacters(in: .whitespacesAndNewlines))
                let expires = Self.parseISO8601(currentExpires.trimmingCharacters(in: .whitespacesAndNewlines))

                alerts.append(WeatherAlert(
                    id: UUID(),
                    title: trimmedTitle,
                    summary: currentSummary.trimmingCharacters(in: .whitespacesAndNewlines),
                    alertURL: url,
                    severity: severity,
                    areaDescription: currentAreaDesc.trimmingCharacters(in: .whitespacesAndNewlines),
                    effectiveDate: effective,
                    expiresDate: expires,
                    sourceHost: feedHost,
                    fetchedAt: Date()
                ))
            }
        }
    }

    func parser(
        _ parser: XMLParser,
        foundCharacters string: String
    ) {
        guard insideEntry else { return }

        let localName = currentElement.contains(":")
            ? String(currentElement.split(separator: ":").last ?? "")
            : currentElement

        switch localName {
        case "title":
            currentTitle += string
        case "summary", "description":
            currentSummary += string
        case "link":
            currentLink += string
        case "severity":
            currentSeverity += string
        case "areaDesc":
            currentAreaDesc += string
        case "effective":
            currentEffective += string
        case "expires":
            currentExpires += string
        default:
            break
        }
    }

    // MARK: - Helpers

    private func mapSeverity(_ raw: String) -> WeatherAlertSeverity {
        switch raw.lowercased() {
        case "extreme": .extreme
        case "severe": .severe
        case "moderate": .moderate
        case "minor": .minor
        default: .unknown
        }
    }

    private static nonisolated(unsafe) let iso8601Formatter = ISO8601DateFormatter()

    private static func parseISO8601(_ string: String) -> Date? {
        guard !string.isEmpty else { return nil }
        return iso8601Formatter.date(from: string)
    }
}
