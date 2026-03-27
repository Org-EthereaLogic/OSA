import XCTest

/// Navigates to an article and prints all visible text for content review.
final class OSAArticleTextDumpTest: XCTestCase {

    @MainActor
    func testDumpWaterArticleText() {
        let app = XCUIApplication()
        app.launch()

        let tabBar = app.tabBars.firstMatch
        guard tabBar.waitForExistence(timeout: 10) else {
            XCTFail("No tab bar")
            return
        }

        tabBar.buttons["Library"].tap()
        sleep(1)

        let water = app.staticTexts["Water"]
        guard water.waitForExistence(timeout: 5) else {
            XCTFail("Water chapter not found")
            return
        }
        water.tap()
        sleep(2)

        // Dump all text on the first visible page
        var allText: [String] = []
        for i in 0..<4 {
            let texts = app.staticTexts.allElementsBoundByIndex
            for t in texts {
                let label = t.label
                if !label.isEmpty && !allText.contains(label) {
                    allText.append(label)
                }
            }
            if i < 3 {
                app.swipeUp()
                sleep(1)
            }
        }

        // Write to a temp file for review
        let joined = allText.joined(separator: "\n---\n")
        let attachment = XCTAttachment(string: joined)
        attachment.name = "Water-Article-Text-Dump"
        attachment.lifetime = .keepAlways
        add(attachment)

        // Check for missing spaces after periods
        var spacingIssues: [String] = []
        for text in allText {
            let pattern = try! NSRegularExpression(pattern: "[a-z]\\.[A-Z]")
            let range = NSRange(text.startIndex..., in: text)
            let matches = pattern.matches(in: text, range: range)
            for match in matches {
                let matchRange = Range(match.range, in: text)!
                let start = text.index(matchRange.lowerBound, offsetBy: max(-20, text.distance(from: text.startIndex, to: matchRange.lowerBound) * -1), limitedBy: text.startIndex) ?? text.startIndex
                let end = text.index(matchRange.upperBound, offsetBy: min(20, text.distance(from: matchRange.upperBound, to: text.endIndex)), limitedBy: text.endIndex) ?? text.endIndex
                spacingIssues.append("...\(text[start..<end])...")
            }
        }

        if !spacingIssues.isEmpty {
            XCTFail("Found \(spacingIssues.count) missing-space-after-period issues:\n\(spacingIssues.joined(separator: "\n"))")
        }
    }
}
