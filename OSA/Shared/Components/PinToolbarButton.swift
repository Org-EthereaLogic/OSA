import SwiftUI

struct PinToolbarButton: View {
    let isPinned: Bool
    let pinLabel: LocalizedStringKey
    let unpinLabel: LocalizedStringKey
    let hint: LocalizedStringKey
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
