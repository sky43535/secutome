//
//  extras.swift
//  secutome
//
//  Created by Owner on 8/1/25.
//

import SwiftUI

struct ExtrasView: View {
    @State private var showPrivacyPolicy = false
    @State private var showTermsAndConditions = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Extras")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .padding(.top)

                    Button("Privacy Policy") {
                        showPrivacyPolicy = true
                    }
                    .foregroundColor(.accentColor)
                    .fullScreenCover(isPresented: $showPrivacyPolicy) {
                        DocumentViewer(title: "Privacy Policy", text: privacyPolicyText, dismiss: { showPrivacyPolicy = false })
                    }

                    Button("Terms and Conditions") {
                        showTermsAndConditions = true
                    }
                    .foregroundColor(.accentColor)
                    .fullScreenCover(isPresented: $showTermsAndConditions) {
                        DocumentViewer(title: "Terms and Conditions", text: termsText, dismiss: { showTermsAndConditions = false })
                    }
                }
                .padding()
            }
        }
    }
}

struct DocumentViewer: View {
    var title: String
    var text: String
    var dismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title)
                        .fontWeight(.bold)
                        .padding(.bottom)

                    Text(renderMarkdownBold(text))
                        .font(.body)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

func renderMarkdownBold(_ text: String) -> AttributedString {
    var result = AttributedString()
    let parts = text.components(separatedBy: "**")

    for (i, part) in parts.enumerated() {
        var attr = AttributedString(part)
        attr.font = i % 2 == 0 ? .body : .body.bold()
        result.append(attr)
    }

    return result
}

// MARK: - Full Privacy Policy

let privacyPolicyText = """
**Last Updated: August 1, 2025**

**1. Introduction**

This Privacy Policy explains how your data is handled within the Secutome app. Your privacy matters, and we are committed to being transparent about what we collect, how it’s stored, and how it’s used.

**2. Data Collection**

We do not collect or transmit your data to any external servers. All personal content—notes, vault entries, and interactions with the AI—is stored locally on your device.

**3. AI Assistant**

The AI assistant is powered by and operated through **Meta**. It is **not a local model**. Prompts sent to the AI may be processed by Meta’s services, and subject to their handling policies.

**4. Skysipher™ Encryption**

If you enable security features, your content is encrypted on-device using **Skysipher™**, which uses Apple’s **Keychain** to store your encryption keys securely. The Keychain is a secure storage system provided by iOS for sensitive credentials and cryptographic keys.

If you skip setting up security, your content will remain **on-device only**, but will **not be encrypted**.

**5. Age Requirement**

This app is designed for users **15 years and older**.

**6. Contact**

If you have any concerns, you may reach us at: **skylerp530@gmail.com**

"""

// MARK: - Full Terms & Conditions

let termsText = """
**Last Updated: August 1, 2025**

**1. Acceptance**

By using the Secutome app, you agree to these Terms and Conditions. If you do not agree, do not use the app.

**2. Intended Use**

Secutome is intended for personal journaling, secure data storage, and assistant interaction. It is not intended for illegal, abusive, or harmful purposes.

**3. Security Notice**

You are responsible for maintaining the security of your device. While encryption is available through **Skysipher™**, it is only active if set up. If you skip security, your data is stored locally but **unencrypted**.

**4. Use of AI**

The AI assistant feature is operated via **Meta**, and usage of this feature may involve interactions processed on Meta’s infrastructure.

**5. No Liability**

The developers of this app are not liable for any loss of data, security breach due to user negligence, or misuse of features.

**6. Age Restriction**

You must be **15 years or older** to use Secutome.

**7. Contact**

For questions or concerns: **skylerp530@gmail.com**
"""

