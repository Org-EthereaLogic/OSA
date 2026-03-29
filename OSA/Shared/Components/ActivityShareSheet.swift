import SwiftUI
import UIKit

struct ActivitySharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
    var subject: String? = nil
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let payload: ActivitySharePayload

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: payload.items,
            applicationActivities: nil
        )
        if let subject = payload.subject {
            controller.setValue(subject, forKey: "subject")
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
