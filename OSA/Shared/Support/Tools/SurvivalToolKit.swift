import Foundation

enum SurvivalToolKit {
    enum MorsePlaybackToken: Equatable {
        case dot
        case dash
        case letterGap
        case wordGap
    }

    enum SignalPulse: Equatable {
        case signal(units: Int)
        case pause(units: Int)
    }

    struct MorseEncoding: Equatable {
        let rendered: String
        let tokens: [MorsePlaybackToken]

        var isEmpty: Bool {
            rendered.isEmpty || tokens.isEmpty
        }
    }

    enum UnitConversionKind: String, CaseIterable, Identifiable {
        case temperature
        case distance
        case elevation
        case weight
        case gallons
        case ounces

        var id: String { rawValue }

        var title: String {
            switch self {
            case .temperature: "Celsius / Fahrenheit"
            case .distance: "Miles / Kilometers"
            case .elevation: "Feet / Meters"
            case .weight: "Pounds / Kilograms"
            case .gallons: "Gallons / Liters"
            case .ounces: "Ounces / Milliliters"
            }
        }

        var primaryUnit: String {
            switch self {
            case .temperature: "C"
            case .distance: "mi"
            case .elevation: "ft"
            case .weight: "lb"
            case .gallons: "gal"
            case .ounces: "oz"
            }
        }

        var secondaryUnit: String {
            switch self {
            case .temperature: "F"
            case .distance: "km"
            case .elevation: "m"
            case .weight: "kg"
            case .gallons: "L"
            case .ounces: "mL"
            }
        }

        fileprivate func convert(_ value: Double, direction: UnitConversionDirection) -> Double {
            switch (self, direction) {
            case (.temperature, .forward):
                (value * 9 / 5) + 32
            case (.temperature, .reverse):
                (value - 32) * 5 / 9
            case (.distance, .forward):
                value * 1.609_344
            case (.distance, .reverse):
                value / 1.609_344
            case (.elevation, .forward):
                value * 0.3048
            case (.elevation, .reverse):
                value / 0.3048
            case (.weight, .forward):
                value * 0.453_592_37
            case (.weight, .reverse):
                value / 0.453_592_37
            case (.gallons, .forward):
                value * 3.785_411_784
            case (.gallons, .reverse):
                value / 3.785_411_784
            case (.ounces, .forward):
                value * 29.573_529_562_5
            case (.ounces, .reverse):
                value / 29.573_529_562_5
            }
        }
    }

    enum UnitConversionDirection: String, CaseIterable, Identifiable {
        case forward
        case reverse

        var id: String { rawValue }
    }

    struct RadioReferenceEntry: Identifiable, Equatable {
        let id: String
        let title: String
        let frequency: String
        let usage: String
        let caution: String
    }

    struct DeclinationEstimate: Equatable {
        let degreesEastPositive: Double

        var formattedValue: String {
            let magnitude = abs(degreesEastPositive)
            let direction = degreesEastPositive >= 0 ? "E" : "W"
            return String(format: "%.1f° %@", magnitude, direction)
        }

        var guidance: String {
            "Add east, subtract west."
        }
    }

    static let radioReferenceEntries: [RadioReferenceEntry] = [
        RadioReferenceEntry(
            id: "noaa-weather-radio",
            title: "NOAA Weather Radio",
            frequency: "162.400-162.550 MHz",
            usage: "Continuous weather alerts and forecast broadcasts. Good for passive monitoring when local conditions are changing.",
            caution: "Receive-only reference. Coverage and transmitter reach vary by terrain."
        ),
        RadioReferenceEntry(
            id: "marine-vhf-16",
            title: "Marine VHF Channel 16",
            frequency: "156.800 MHz",
            usage: "International distress, safety, and calling channel for marine use.",
            caution: "Use follows marine radio rules. Monitor for distress if equipped; routine conversation should move off Channel 16 when possible."
        ),
        RadioReferenceEntry(
            id: "cb-channel-9",
            title: "CB Channel 9",
            frequency: "27.065 MHz",
            usage: "Emergency or traveler-assistance calling reference in some areas.",
            caution: "Actual local monitoring varies. Do not assume emergency services are listening."
        ),
        RadioReferenceEntry(
            id: "frs-gmrs",
            title: "FRS / GMRS Family Channels",
            frequency: "462-467 MHz family-band channels",
            usage: "Short-range family or group coordination when cellular service is unavailable.",
            caution: "GMRS transmission may require a license. Channel availability, power limits, and repeater use depend on the radio service."
        ),
        RadioReferenceEntry(
            id: "ham-2m-calling",
            title: "2 m Amateur Calling Frequency",
            frequency: "146.520 MHz",
            usage: "Common U.S. simplex calling frequency for amateur radio operators.",
            caution: "Reference only. Transmit only when trained, equipped, and legally authorized."
        )
    ]

    static let radioDisclaimer = "Reference only. Channel use, monitoring, and licensing rules vary by service and location."
    static let declinationCoverageDescription = "Approximate Pacific Northwest coverage only: 42°-49° N, 125°-116° W."
    static let declinationPrecisionNote = "Approximate field reference only; verify against a current map when precision matters."

    static func encodeMorse(_ text: String) -> MorseEncoding {
        let supportedWords = text
            .uppercased()
            .split(whereSeparator: \.isWhitespace)
            .map { word in
                word.compactMap { morseAlphabet[$0] }
            }
            .filter { !$0.isEmpty }

        guard !supportedWords.isEmpty else {
            return MorseEncoding(rendered: "", tokens: [])
        }

        var renderedWords: [String] = []
        var tokens: [MorsePlaybackToken] = []

        for (wordIndex, word) in supportedWords.enumerated() {
            renderedWords.append(word.joined(separator: " "))

            for (characterIndex, code) in word.enumerated() {
                for symbol in code {
                    tokens.append(symbol == "." ? .dot : .dash)
                }

                if characterIndex < word.count - 1 {
                    tokens.append(.letterGap)
                }
            }

            if wordIndex < supportedWords.count - 1 {
                tokens.append(.wordGap)
            }
        }

        return MorseEncoding(
            rendered: renderedWords.joined(separator: " / "),
            tokens: tokens
        )
    }

    static func convert(
        value: Double,
        kind: UnitConversionKind,
        direction: UnitConversionDirection
    ) -> Double {
        kind.convert(value, direction: direction)
    }

    static func signalPulses(for tokens: [MorsePlaybackToken]) -> [SignalPulse] {
        var pulses: [SignalPulse] = []

        for index in tokens.indices {
            let token = tokens[index]

            switch token {
            case .dot:
                pulses.append(.signal(units: 1))
            case .dash:
                pulses.append(.signal(units: 3))
            case .letterGap:
                pulses.append(.pause(units: 3))
            case .wordGap:
                pulses.append(.pause(units: 7))
            }

            guard index < tokens.index(before: tokens.endIndex) else { continue }

            switch (token, tokens[tokens.index(after: index)]) {
            case (.dot, .dot), (.dot, .dash), (.dash, .dot), (.dash, .dash):
                pulses.append(.pause(units: 1))
            default:
                break
            }
        }

        return mergedPulses(pulses)
    }

    static func estimateDeclination(latitude: Double, longitude: Double) -> DeclinationEstimate? {
        guard isSupportedDeclinationCoordinate(latitude: latitude, longitude: longitude) else {
            return nil
        }

        let weightedAnchors = declinationAnchors.map { anchor -> (weight: Double, degrees: Double) in
            let distance = max(hypot(latitude - anchor.latitude, longitude - anchor.longitude), 0.15)
            let weight = 1.0 / (distance * distance)
            return (weight: weight, degrees: anchor.degreesEastPositive)
        }

        let totalWeight = weightedAnchors.reduce(0.0) { $0 + $1.weight }
        let weightedDegrees = weightedAnchors.reduce(0.0) { $0 + ($1.weight * $1.degrees) }

        guard totalWeight > 0 else { return nil }

        return DeclinationEstimate(degreesEastPositive: weightedDegrees / totalWeight)
    }

    static func isSupportedDeclinationCoordinate(latitude: Double, longitude: Double) -> Bool {
        (42...49).contains(latitude) && (-125 ... -116).contains(longitude)
    }

    private struct DeclinationAnchor {
        let latitude: Double
        let longitude: Double
        let degreesEastPositive: Double
    }

    private static let morseAlphabet: [Character: String] = [
        "A": ".-",
        "B": "-...",
        "C": "-.-.",
        "D": "-..",
        "E": ".",
        "F": "..-.",
        "G": "--.",
        "H": "....",
        "I": "..",
        "J": ".---",
        "K": "-.-",
        "L": ".-..",
        "M": "--",
        "N": "-.",
        "O": "---",
        "P": ".--.",
        "Q": "--.-",
        "R": ".-.",
        "S": "...",
        "T": "-",
        "U": "..-",
        "V": "...-",
        "W": ".--",
        "X": "-..-",
        "Y": "-.--",
        "Z": "--..",
        "0": "-----",
        "1": ".----",
        "2": "..---",
        "3": "...--",
        "4": "....-",
        "5": ".....",
        "6": "-....",
        "7": "--...",
        "8": "---..",
        "9": "----."
    ]

    private static let declinationAnchors: [DeclinationAnchor] = [
        DeclinationAnchor(latitude: 48.76, longitude: -122.48, degreesEastPositive: 15.8),
        DeclinationAnchor(latitude: 47.61, longitude: -122.33, degreesEastPositive: 15.6),
        DeclinationAnchor(latitude: 47.66, longitude: -117.43, degreesEastPositive: 14.2),
        DeclinationAnchor(latitude: 45.52, longitude: -122.68, degreesEastPositive: 15.2),
        DeclinationAnchor(latitude: 44.06, longitude: -121.32, degreesEastPositive: 14.8),
        DeclinationAnchor(latitude: 44.05, longitude: -123.09, degreesEastPositive: 15.0),
        DeclinationAnchor(latitude: 43.62, longitude: -116.20, degreesEastPositive: 13.7),
        DeclinationAnchor(latitude: 42.33, longitude: -122.88, degreesEastPositive: 14.4)
    ]

    private static func mergedPulses(_ pulses: [SignalPulse]) -> [SignalPulse] {
        var merged: [SignalPulse] = []

        for pulse in pulses {
            guard let last = merged.last else {
                merged.append(pulse)
                continue
            }

            switch (last, pulse) {
            case (.pause(let previousUnits), .pause(let nextUnits)):
                merged[merged.count - 1] = .pause(units: previousUnits + nextUnits)
            case (.signal(let previousUnits), .signal(let nextUnits)):
                merged[merged.count - 1] = .signal(units: previousUnits + nextUnits)
            default:
                merged.append(pulse)
            }
        }

        return merged
    }
}
