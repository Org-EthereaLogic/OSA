import SwiftUI

struct PinToolbarButton: View {
    let isPinned: Bool
    let pinLabel: String
    let unpinLabel: String
    let hint: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPinned ? "pin.fill" : "pin")
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .accessibilityLabel(isPinned ? unpinLabel : pinLabel)
        .accessibilityHint(hint)
    }
}
