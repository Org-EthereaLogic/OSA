import SwiftUI
import WebKit

struct LocalSVGIllustrationView: View {
    let attachment: LocalMediaAttachment

    @AppStorage(AccessibilitySettings.appLanguageKey)
    private var appLanguageRawValue = AccessibilitySettings.appLanguageDefault.rawValue
    @State private var svgMarkup: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if let svgMarkup {
                SVGWebView(svgMarkup: svgMarkup)
                    .frame(height: CGFloat(attachment.preferredHeight ?? 220))
                    .background(.osaBackground, in: RoundedRectangle(cornerRadius: CornerRadius.md))
                    .overlay {
                        RoundedRectangle(cornerRadius: CornerRadius.md)
                            .stroke(Color.osaHairline, lineWidth: 1)
                    }
            } else {
                ContentUnavailableView(
                    "Illustration Unavailable",
                    systemImage: "photo.badge.exclamationmark",
                    description: Text("This local illustration could not be loaded from the app bundle.")
                )
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
            }

            Text(attachment.caption(for: appLanguage))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(attachment.accessibilityLabel(for: appLanguage))
        .task {
            svgMarkup = loadSVGMarkup()
        }
    }

    private var appLanguage: AppLanguage {
        AccessibilitySettings.appLanguage(from: appLanguageRawValue)
    }

    private func loadSVGMarkup(bundle: Bundle = .main) -> String? {
        guard let svgURL = bundle.resourceURL?.appendingPathComponent(attachment.bundlePath) else {
            return nil
        }

        guard let rawMarkup = try? String(contentsOf: svgURL, encoding: .utf8) else {
            return nil
        }

        return """
        <!doctype html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
          <style>
            html, body {
              margin: 0;
              padding: 0;
              background: transparent;
              overflow: hidden;
            }
            svg {
              width: 100%;
              height: auto;
              display: block;
            }
          </style>
        </head>
        <body>
        \(rawMarkup)
        </body>
        </html>
        """
    }
}

private struct SVGWebView: UIViewRepresentable {
    let svgMarkup: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = false
        configuration.websiteDataStore = .nonPersistent()

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.navigationDelegate = context.coordinator
        webView.accessibilityIgnoresInvertColors = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        webView.loadHTMLString(svgMarkup, baseURL: nil)
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
        ) {
            if navigationAction.request.url == nil {
                decisionHandler(.allow)
                return
            }

            if navigationAction.navigationType == .other,
               navigationAction.request.url?.scheme == "about" {
                decisionHandler(.allow)
                return
            }

            decisionHandler(.cancel)
        }
    }
}
