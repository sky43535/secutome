//
//  setup.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//

import SwiftUI
import CryptoKit

struct SecuritySetupView: View {
    @State private var generatedPin: [String] = []
    @State private var userPinInput: [String] = []
    @State private var pinConfirmed = false
    @State private var showSetupCompleteAlert = false

    var onSetupComplete: () -> Void

    private let symbolPool = ["moon", "rainbow", "flame", "bolt", "mountain.2", "hare", "bird", "lizard", "pawprint", "tree", "atom", "figure"]
    private let pinLength = 6

    var body: some View {
        VStack(spacing: 28) {
            Text(" Your Skycipher Symbol PIN")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .padding(.top, 30)

            HStack(spacing: 16) {
                ForEach(generatedPin, id: \.self) { symbol in
                    Image(systemName: symbol)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42, height: 42)
                        .foregroundStyle(LinearGradient(
                            gradient: Gradient(colors: [.cyan, .blue]),
                            startPoint: .top,
                            endPoint: .bottom)
                        )
                        .padding(6)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }
            .padding(.bottom)

            if !pinConfirmed {
                VStack(spacing: 14) {
                    Text(" Re-enter symbols to confirm your secure PIN.")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    PinInputView(pin: $userPinInput, onComplete: checkPinMatch)
                        .padding(.top, 10)
                }
            } else {
                Button(action: {
                    saveEncryptedPin()
                }) {
                    HStack {
                        Image(systemName: "checkmark.seal.fill")
                        Text("Finish Setup")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green)
                    .cornerRadius(16)
                    .shadow(color: .green.opacity(0.3), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.black, Color.blue.opacity(0.4)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .onAppear(perform: generatePin)
        .alert(isPresented: $showSetupCompleteAlert) {
            Alert(
                title: Text(" Setup Complete"),
                message: Text("Your encrypted PIN has been saved securely with skycipher."),
                dismissButton: .default(Text("Continue"), action: onSetupComplete)
            )
        }
    }

    func generatePin() {
        var pin: [String] = []
        for _ in 0..<pinLength {
            if let random = symbolPool.randomElement() {
                pin.append(random)
            }
        }
        generatedPin = pin
    }

    func checkPinMatch() {
        if userPinInput == generatedPin {
            pinConfirmed = true
        } else {
            userPinInput.removeAll()
        }
    }

    func saveEncryptedPin() {
        let pinString = generatedPin.joined(separator: "-")
        let pinData = Data(pinString.utf8)

        do {
            // Retrieve or create the encryption key securely
            let key = try KeychainHelper.shared.getOrCreateKey()

            // Encrypt the PIN data
            let sealedBox = try AES.GCM.seal(pinData, using: key)
            if let combined = sealedBox.combined {
                UserDefaults.standard.set(combined, forKey: "encryptedPin")
                showSetupCompleteAlert = true
            }
        } catch {
            print("Encryption error: \(error.localizedDescription)")
        }
    }
}
