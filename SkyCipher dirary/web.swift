//
//  web.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//
import SwiftUI
import WebKit

struct LockedWebView: UIViewRepresentable {
    let allowedDomain: String
    let allowedURL: URL

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.load(URLRequest(url: allowedURL))
        webView.allowsBackForwardNavigationGestures = false
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(allowedDomain: allowedDomain)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let allowedDomain: String

        init(allowedDomain: String) {
            self.allowedDomain = allowedDomain
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
                     decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let host = navigationAction.request.url?.host else {
                decisionHandler(.cancel)
                return
            }

            if host.contains(allowedDomain) {
                decisionHandler(.allow)
            } else {
                decisionHandler(.cancel)
            }
        }
    }
}

struct WebsiteTabView: View {
    var body: some View {
        NavigationView {
            LockedWebView(
                allowedDomain: "idid-8b262.web.app",
                allowedURL: URL(string: "https://idid-8b262.web.app")!
            )
            .edgesIgnoringSafeArea(.all)
            .navigationTitle("safe haven")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
