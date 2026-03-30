import Foundation

enum GPXExporter {
    static func gpxString(for track: RecordedTrack) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let metadataTime = formatter.string(from: track.startedAt)
        let points = track.points
            .sorted { $0.timestamp < $1.timestamp }
            .map { point in
                """
                        <trkpt lat="\(point.latitude)" lon="\(point.longitude)">
                            <time>\(formatter.string(from: point.timestamp))</time>
                        </trkpt>
                """
            }
            .joined(separator: "\n")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="OSA" xmlns="http://www.topografix.com/GPX/1/1">
            <metadata>
                <name>\(escaped(track.title))</name>
                <time>\(metadataTime)</time>
            </metadata>
            <trk>
                <name>\(escaped(track.title))</name>
                <trkseg>
        \(points)
                </trkseg>
            </trk>
        </gpx>
        """
    }

    static func exportFile(for track: RecordedTrack) throws -> URL {
        let fileName = slugified(track.title.isEmpty ? "recorded-track" : track.title)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(fileName)
            .appendingPathExtension("gpx")

        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }

        try gpxString(for: track).write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }

    private static func slugified(_ value: String) -> String {
        let allowed = CharacterSet.alphanumerics.union(.whitespaces)
        let sanitized = value.unicodeScalars
            .map { allowed.contains($0) ? String($0) : " " }
            .joined()
        let parts = sanitized.lowercased().split(whereSeparator: \.isWhitespace)
        return parts.isEmpty ? "recorded-track" : parts.joined(separator: "-")
    }
}
