import SwiftUI

enum BrandWordmarkVariant {
    case primary
    case reversed
}

struct BrandWordmarkView: View {
    let variant: BrandWordmarkVariant
    let height: CGFloat

    init(variant: BrandWordmarkVariant = .primary, height: CGFloat = 36) {
        self.variant = variant
        self.height = height
    }

    var body: some View {
        Image(assetName)
            .resizable()
            .interpolation(.high)
            .renderingMode(.original)
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel(AppBrand.displayName)
    }

    private var assetName: String {
        switch variant {
        case .primary:
            "LanternWordmark"
        case .reversed:
            "LanternWordmarkWhite"
        }
    }
}

#Preview {
    VStack(spacing: Spacing.lg) {
        BrandWordmarkView(height: 34)
        BrandWordmarkView(variant: .reversed, height: 34)
            .padding()
            .background(.osaNight, in: RoundedRectangle(cornerRadius: CornerRadius.md))
    }
    .padding()
    .background(.osaBackground)
}
