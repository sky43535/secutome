//
//  ContentView.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//

import SwiftUI
import LocalAuthentication

struct ContentView: View {
    @AppStorage("didSkipSecurity") private var securitySkipped: Bool = false
    @AppStorage("didCompleteSetup") private var didCompleteSetup: Bool = false
    @State private var showOnboarding = true
    @State private var isUnlocked = false
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if showOnboarding {
                OnboardingView(onContinue: {
                    showOnboarding = false
                }, onSkipSecurity: {
                    securitySkipped = true
                    showOnboarding = false
                    isUnlocked = true
                })
            } else if isUnlocked || securitySkipped {
                TabView(selection: $selectedTab) {
                    DiaryView()
                        .tabItem {
                            Label("Diary", systemImage: "book.closed")
                        }
                        .tag(0)
                    
                    NavigationView {
                        AIAssistantView()
                    }
                    .tabItem {
                        Label("AI Assistant", systemImage: "message")
                    }
                    .tag(1)
                    
                    
                    NavigationView {
                        ConfessionShredderView()
                    }
                    .tabItem {
                        Label("confession shredder", systemImage: "scissors")
                    }
                    .tag(2)
                   
                    
                    
                    NavigationView {
                        SecureStorageTab()
                    }
                    .tabItem {
                        Label("vault ", systemImage: "lock.shield")
                    }
                    .tag(3)
                    
                    NavigationView {
                        ExtrasView ()
                    }
                    .tabItem {
                        Label("extras ", systemImage: "ellipsis.circle")
                    }
                    .tag(4)
                }
            
                .accentColor(.accentColor)
            } else if didCompleteSetup {
                UnlockFlowView(onUnlockSuccess: {
                    isUnlocked = true
                })
            } else {
                SecuritySetupView(onSetupComplete: {
                    didCompleteSetup = true
                    isUnlocked = true
                })
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
                showOnboarding = false
            } else {
                UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            }
        }
    }
}








struct OnboardingView: View {
    var onContinue: () -> Void
    var onSkipSecurity: () -> Void

    @State private var currentPage = 0
    private let totalPages = 8

    let backgrounds: [LinearGradient] = [
        LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.purple, .blue], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.orange, .pink], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.mint, .teal], startPoint: .topLeading, endPoint: .bottomTrailing),
        LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing), // Vault
        LinearGradient(colors: [.purple, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing), // Support
        LinearGradient(colors: [.red, .green], startPoint: .topLeading, endPoint: .bottomTrailing), // Apple
        LinearGradient(colors: [.accentColor, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
    ]

    var body: some View {
        ZStack {
            backgrounds[currentPage]
                .edgesIgnoringSafeArea(.all)
                .animation(.easeInOut(duration: 0.4), value: currentPage)

            VStack {
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        VStack(spacing: 24) {
                            Spacer()

                            Image(systemName: pageIcon(for: index))
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .foregroundColor(.white)
                                .shadow(radius: 10)

                            Text(pageTitle(for: index))
                                .font(.system(size: 34, weight: .heavy))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .shadow(radius: 2)

                            Text(pageDescription(for: index))
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                                .padding(.bottom, 10)

                            Spacer()
                        }
                        .tag(index)
                        .padding(.vertical)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                HStack {
                    Button(action: onSkipSecurity) {
                        Text("Skip Security Setup")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.8))
                            .underline()
                    }

                    Spacer()

                    if currentPage == totalPages - 1 {
                        Button(action: onContinue) {
                            Text("Enter via skysipher™")
                                .fontWeight(.bold)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    } else {
                        Button(action: { withAnimation { currentPage += 1 } }) {
                            Text("Next")
                                .fontWeight(.medium)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.white.opacity(0.2))
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 4)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
        }
    }

    func pageTitle(for index: Int) -> String {
        [
            "Meet Your Built-In AI",
            "Your Secure Diary",
            "Multi-Layered Protection",
            "Private access,state of the art security",
            "Your Secure Vault",
            "Need Help? We’re Here",
            "Thank You, Apple ❤️",
            "the confession, shredder"
        ][index]
    }

    func pageDescription(for index: Int) -> String {
        [
            "Get help journaling, reflecting, or just asking questions. Your AI assistant lives here — powered by Meta’s Llama 3 and SkysMind™ privacy filters.",
            "Keep your thoughts safe with state-of-the-art encryption and biometric security. Simple, elegant, and personal.",
            "Unlock with Face ID, a custom symbol PIN, and more. with SkyCipher™ security and apple",
            "Your notes are saved on device with state-of-the-art encryption. Powered by SkysMind™ — privacy, reimagined. (Note: if security setup is skipped, no data will be encrypted. Contact support for details.)",
            "Store your most sensitive info like crypto keys, access pins, and passwords — all encrypted and guarded.",
            "Questions? Feedback? Or need help setting up? Reach out anytime at skylerp530@gmail.com — we care.",
            "Built on a foundation of privacy, creativity, and care — made possible by a platform that empowers anyone to build for everyone. This app is a small thank-you to the ecosystem of apple that inspires safer, smarter, and more meaningful digital spaces.",
            "A private, secure space to write down your thoughts and feelings — then destroy them instantly. Type your confession, tap Shred, and watch your words visually break apart and disappear with a smooth animation. Once shredded, the text is permanently erased, and a gentle confirmation toast lets you know your secret is safe. Perfect for those moments when you just need to let go without saving a trace."
        ][index]
    }

    func pageIcon(for index: Int) -> String {
        [
            "sparkles",
            "lock.shield",
            "person.crop.circle.badge.checkmark",
            "calendar",
            "lock.vault",
            "questionmark.bubble",
            "apple.logo",
            "scissors"
        ][index]
    }
}
