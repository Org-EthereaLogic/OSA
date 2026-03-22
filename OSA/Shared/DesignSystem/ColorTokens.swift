import SwiftUI

extension ShapeStyle where Self == Color {
    static var osaPrimary: Color { Color("AccentColor") }
    static var osaBackground: Color { Color(.systemGroupedBackground) }
    static var osaSecondaryBackground: Color { Color(.secondarySystemGroupedBackground) }
    static var osaSurface: Color { Color(.systemBackground) }
}
