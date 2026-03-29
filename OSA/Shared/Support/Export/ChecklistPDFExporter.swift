import CoreGraphics
import Foundation
import UIKit

struct ChecklistPDFSection: Equatable {
    let heading: String?
    let lines: [String]
}

struct ChecklistPDFDocument: Equatable {
    let title: String
    let filename: String
    let sections: [ChecklistPDFSection]
}

enum ChecklistPDFExporter {
    private static let pageBounds = CGRect(x: 0, y: 0, width: 612, height: 792)

    static func document(for template: ChecklistTemplate) -> ChecklistPDFDocument {
        let metadata = ChecklistPDFSection(
            heading: "Summary",
            lines: [
                "Category: \(template.category.capitalized.replacingOccurrences(of: "-", with: " "))",
                "Estimated Time: \(template.estimatedMinutes) minutes",
                "Style: \(template.presentationStyle == .emergencyProtocol ? "Emergency Protocol" : "Checklist")",
                template.lastReviewedAt.map {
                    "Reviewed: \($0.formatted(date: .abbreviated, time: .omitted))"
                }
            ]
            .compactMap { $0 }
        )

        let items = template.items
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { item in
                var line = "• \(item.text)"
                if item.isOptional {
                    line += " (Optional)"
                }
                if let detail = item.detail, !detail.isEmpty {
                    line += " — \(detail)"
                }
                return line
            }

        return ChecklistPDFDocument(
            title: template.title,
            filename: fileName(for: template.slug, ext: "pdf"),
            sections: [
                metadata,
                ChecklistPDFSection(heading: "Items", lines: items)
            ]
        )
    }

    static func document(for run: ChecklistRun) -> ChecklistPDFDocument {
        let completedCount = run.items.filter(\.isComplete).count
        let metadata = ChecklistPDFSection(
            heading: "Summary",
            lines: [
                "Status: \(displayText(for: run.status))",
                "Started: \(run.startedAt.formatted(date: .abbreviated, time: .shortened))",
                run.completedAt.map {
                    "Completed: \($0.formatted(date: .abbreviated, time: .shortened))"
                },
                "Progress: \(completedCount) of \(run.items.count) complete"
            ]
            .compactMap { $0 }
        )

        let context = ChecklistPDFSection(
            heading: "Context",
            lines: run.contextNote.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            .map { [$0] } ?? []
        )

        let items = run.items
            .sorted { $0.sortOrder < $1.sortOrder }
            .map { item in
                let prefix = item.isComplete ? "[x]" : "[ ]"
                if let completedAt = item.completedAt {
                    return "\(prefix) \(item.text) — Completed \(completedAt.formatted(date: .abbreviated, time: .shortened))"
                }
                return "\(prefix) \(item.text)"
            }

        return ChecklistPDFDocument(
            title: run.title,
            filename: fileName(for: run.title, ext: "pdf"),
            sections: [
                metadata,
                context,
                ChecklistPDFSection(heading: "Items", lines: items)
            ]
            .filter { !$0.lines.isEmpty }
        )
    }

    static func exportTemplate(_ template: ChecklistTemplate) throws -> URL {
        try export(document: document(for: template))
    }

    static func exportRun(_ run: ChecklistRun) throws -> URL {
        try export(document: document(for: run))
    }

    private static func export(document: ChecklistPDFDocument) throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: pageBounds)
        let data = renderer.pdfData { context in
            var cursorY: CGFloat = 48

            context.beginPage()
            cursorY = draw(
                text: document.title,
                in: CGRect(x: 48, y: cursorY, width: pageBounds.width - 96, height: 40),
                attributes: titleAttributes()
            ).maxY + 20

            for section in document.sections {
                if let heading = section.heading {
                    let headingRect = CGRect(x: 48, y: cursorY, width: pageBounds.width - 96, height: 24)
                    if headingRect.maxY >= pageBounds.height - 60 {
                        context.beginPage()
                        cursorY = 48
                    }
                    cursorY = draw(
                        text: heading,
                        in: CGRect(x: 48, y: cursorY, width: pageBounds.width - 96, height: 24),
                        attributes: headingAttributes()
                    ).maxY + 8
                }

                for line in section.lines {
                    let maxRect = CGRect(
                        x: 48,
                        y: cursorY,
                        width: pageBounds.width - 96,
                        height: pageBounds.height - cursorY - 48
                    )
                    let measured = boundingRect(for: line, in: maxRect, attributes: bodyAttributes())
                    if cursorY + measured.height >= pageBounds.height - 48 {
                        context.beginPage()
                        cursorY = 48
                    }

                    cursorY = draw(
                        text: line,
                        in: CGRect(x: 48, y: cursorY, width: pageBounds.width - 96, height: measured.height + 6),
                        attributes: bodyAttributes()
                    ).maxY + 8
                }

                cursorY += 8
            }
        }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent(document.filename)
        if FileManager.default.fileExists(atPath: url.path) {
            try FileManager.default.removeItem(at: url)
        }
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func draw(
        text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGRect {
        let textRect = boundingRect(for: text, in: rect, attributes: attributes)
        let drawRect = CGRect(origin: rect.origin, size: CGSize(width: rect.width, height: textRect.height))
        (text as NSString).draw(
            with: drawRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        return drawRect
    }

    private static func boundingRect(
        for text: String,
        in rect: CGRect,
        attributes: [NSAttributedString.Key: Any]
    ) -> CGRect {
        (text as NSString).boundingRect(
            with: CGSize(width: rect.width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: attributes,
            context: nil
        )
        .integral
    }

    private static func titleAttributes() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.boldSystemFont(ofSize: 22)]
    }

    private static func headingAttributes() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.boldSystemFont(ofSize: 14)]
    }

    private static func bodyAttributes() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.systemFont(ofSize: 11)]
    }

    private static func displayText(for status: ChecklistRunStatus) -> String {
        switch status {
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        case .abandoned:
            return "Abandoned"
        }
    }

    private static func fileName(for rawTitle: String, ext: String) -> String {
        let slug = rawTitle
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9]+", with: "-", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))

        return "\(slug.isEmpty ? "checklist-export" : slug).\(ext)"
    }
}
