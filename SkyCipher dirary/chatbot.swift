//
//  chatbot.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//

import SwiftUI
import AVFoundation

struct AIAssistantView: View {
    @State private var userInput: String = ""
    @State private var assistantReply: String = "Ask me something!"
    @State private var isSpeaking = false
    @State private var showToast = false
    @State private var isLoading = false

    let synthesizer = AVSpeechSynthesizer()
    
    // ⬅️ INSERT YOUR KEY + MODEL HERE
    let apiKey = "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"
    let model = "meta-llama/llama-3.1-405b-instruct:free" // Or any OpenRouter-supported model
    private let systemPrompt = """
    You are a highly intelligent, insightful, and knowledgeable AI assistant designed to provide in-depth, thoughtful, and nuanced answers on a wide range of topics, especially tailored to chat with teens with empathy and clarity. Your goal is to be as helpful, honest, and precise as possible, including providing detailed explanations and exploring complex ideas.

    While you are encouraged to be open-minded and engage with difficult or controversial topics in a mature and respectful way, you must always avoid any content or advice that promotes harm, illegal activities, violence, self-harm, or discrimination of any kind.

    You should:
    - Provide comprehensive and well-reasoned responses, including relevant context and multiple perspectives when appropriate.
    - Clarify ambiguous questions by asking for more details.
    - Encourage critical thinking and curiosity.
    - Avoid censorship of important but sensitive topics, while framing responses responsibly.
    - Never assist with or promote actions that could endanger the user or others.
    - Maintain a respectful and professional tone.

    If asked about harmful or illegal content, respond with a clear explanation of why you cannot assist, and if appropriate, suggest safe, legal alternatives or professional resources.
    """
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Assistant Reply:")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        Text(assistantReply)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color.pink.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer()

                HStack(spacing: 12) {
                    TextField("Type a question... (limit 1 per minute)", text: $userInput)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding(.horizontal)
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    dismissKeyboard()
                                }
                            }
                        }

                    Button(action: sendToAI) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                    }
                    .disabled(userInput.isEmpty || isLoading)
                }

                HStack(spacing: 16) {
                    Button(action: copyReply) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button(action: toggleSpeaking) {
                        Label(isSpeaking ? "Stop Reading" : "Read Aloud",
                              systemImage: isSpeaking ? "stop.circle" : "speaker.wave.2.fill")
                    }
                }
                .padding(.top)
            }
            .padding()
            .navigationTitle("AI Assistant")
            .foregroundColor(.accentColor)
            .navigationBarTitleDisplayMode(.inline)
            .overlay(toastView, alignment: .bottom)
        }
    }

    private func sendToAI() {
        guard !userInput.isEmpty else { return }
        isLoading = true
        dismissKeyboard()

        Task {
            defer { isLoading = false }
            do {
                let result = try await callOpenRouterAPI(systemPrompt: systemPrompt, userInput: userInput)
                assistantReply = result
                userInput = ""
            } catch {
                assistantReply = "Something went wrong. \(error.localizedDescription)"
            }
        }
    }

    private func callOpenRouterAPI(systemPrompt: String, userInput: String) async throws -> String {
        guard let url = URL(string: "https://openrouter.ai/api/v1/chat/completions") else {
            throw URLError(.badURL)
        }

        let headers = [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]

        let payload: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userInput]
            ]
        ]

        let body = try JSONSerialization.data(withJSONObject: payload, options: [])

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let result = try JSONDecoder().decode( OpenRouterChatResponse.self, from: data)
        return result.choices.first?.message.content ?? "No reply."
    }

    private func toggleSpeaking() {
        if isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
            isSpeaking = false
        } else {
            let utterance = AVSpeechUtterance(string: assistantReply)
            utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
            utterance.rate = 0.45
            synthesizer.speak(utterance)
            isSpeaking = true
        }
    }

    private func copyReply() {
        UIPasteboard.general.string = assistantReply
        showCopiedToast()
    }

    private func showCopiedToast() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        withAnimation {
            showToast = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }

    @ViewBuilder
    private var toastView: some View {
        if showToast {
            Text("Copied to Clipboard!")
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(16)
                .shadow(radius: 4)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 40)
        }
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil, from: nil, for: nil)
    }
}

struct  OpenRouterChatResponse: Codable {
    struct Choice: Codable {
        struct Message: Codable {
            let content: String
        }
        let message: Message
    }
    let choices: [Choice]
}
