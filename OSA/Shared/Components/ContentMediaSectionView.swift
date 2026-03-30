import SwiftUI

struct ContentMediaSectionView: View {
    let attachments: [LocalMediaAttachment]

    var body: some View {
        if !attachments.isEmpty {
            VStack(alignment: .leading, spacing: Spacing.md) {
                Text("Illustrations And Media")
                    .font(.sectionHeader)
                    .accessibilityAddTraits(.isHeader)

                ForEach(attachments) { attachment in
                    switch attachment.kind {
                    case .inlineSVG:
                        LocalSVGIllustrationView(attachment: attachment)
                    case .shortVideo:
                        LocalVideoPlayerView(attachment: attachment)
                    }
                }
            }
        }
    }
}
