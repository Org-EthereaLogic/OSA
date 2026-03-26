import SwiftUI

struct BrandMarkView: View {
    let size: CGFloat

    init(size: CGFloat = 56) {
        self.size = size
    }

    var body: some View {
        Image("LanternMark")
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    VStack(spacing: Spacing.md) {
        BrandMarkView(size: 40)
        BrandMarkView(size: 64)
    }
    .padding()
    .background(.osaBackground)
}
