import AVKit
import SwiftUI

struct LocalVideoPlayerView: View {
    let attachment: LocalMediaAttachment

    @AppStorage(AccessibilitySettings.appLanguageKey)
    private var appLanguageRawValue = AccessibilitySettings.appLanguageDefault.rawValue
    @State private var player: AVPlayer?
    @State private var assetURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let player {
                VideoPlayer(player: player)
                    .frame(height: CGFloat(attachment.preferredHeight ?? 220))
                    .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.osaHairline, lineWidth: 1)
                    }
                    .onDisappear {
                        player.pause()
                    }
            } else {
                ContentUnavailableView(
                    "Video Unavailable",
                    systemImage: "video.slash",
                    description: Text("This bundled clip could not be loaded from the app bundle.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }

            Text(attachment.caption(for: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let transcript = attachment.transcript(for: appLanguage), !transcript.isEmpty {
                DisclosureGroup("Transcript") {
                    Text(transcript)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, Spacing.xs)
                }
                .font(.caption.weight(.semibold))
                .tint(.osaPrimary)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(attachment.accessibilityLabel(for: appLanguage))
        .accessibilityHint(
            attachment.transcript(for: appLanguage) == nil
                ? Text("")
                : Text("Transcript available below.")
        )
        .task {
            guard let localURL = Bundle.main.resourceURL?.appendingPathComponent(attachment.bundlePath) else {
                return
            }
            assetURL = localURL
            player = AVPlayer(url: localURL)
        }
    }

    private var appLanguage: AppLanguage {
        AccessibilitySettings.appLanguage(from: appLanguageRawValue)
    }
}
