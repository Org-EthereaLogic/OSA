import SwiftUI

struct AskScreen: View {
    @State private var query = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: Spacing.lg) {
                    // Scope label
                    Label("Local sources only", systemImage: "internaldrive.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, Spacing.xl)

                    // Zero state
                    VStack(spacing: Spacing.md) {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.tertiary)
                        Text("Ask a question about your handbook, inventory, or notes.")
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.secondary)
                        Text("Answers are grounded in approved local content with citations.")
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, Spacing.xxl)
                    .padding(.top, Spacing.xxxl)
                }
            }

            // Input composer
            HStack(spacing: Spacing.sm) {
                TextField("Ask a question...", text: $query)
                    .textFieldStyle(.roundedBorder)
                Button {
                    // Submit action placeholder
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .disabled(query.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(Spacing.lg)
            .background(.osaSurface)
        }
        .navigationTitle("Ask")
    }
}

#Preview {
    NavigationStack {
        AskScreen()
    }
}
