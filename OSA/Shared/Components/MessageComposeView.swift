import MessageUI
import SwiftUI

struct MessageComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let body: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> MFMessageComposeViewController {
        let controller = MFMessageComposeViewController()
        controller.messageComposeDelegate = context.coordinator
        controller.recipients = recipients
        controller.body = body
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMessageComposeViewController, context: Context) {}

    final class Coordinator: NSObject, MFMessageComposeViewControllerDelegate {
        nonisolated func messageComposeViewController(
            _ controller: MFMessageComposeViewController,
            didFinishWith result: MessageComposeResult
        ) {
            Task { @MainActor in
                controller.dismiss(animated: true)
            }
        }
    }
}
