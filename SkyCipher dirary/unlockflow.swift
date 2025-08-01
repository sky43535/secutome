//
//  unlockflow.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//

import SwiftUI
import LocalAuthentication
import CryptoKit

struct UnlockFlowView: View {
    @State private var biometricPassed = false
    @State private var pinInput: [String] = []
    @State private var showFailureAlert = false
    @State private var failureMessage = ""
    
    var onUnlockSuccess: () -> Void
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [.indigo.opacity(0.8), .blue.opacity(0.6)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 40) {
                if !biometricPassed {
                    BiometricAuthView(onSuccess: {
                        biometricPassed = true
                    }, onFail: {
                        failureMessage = "Biometric authentication failed."
                        showFailureAlert = true
                    })
                } else {
                    VStack(spacing: 20) {
                        Text(" Enter Your PIN")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                            .padding(.top, 20)
                        
                        PinInputView(pin: $pinInput, onComplete: verifyPin)
                            .padding(.horizontal)
                    }
                }
            }
            .padding()
            .alert(isPresented: $showFailureAlert) {
                Alert(title: Text("Unlock Failed"),
                      message: Text(failureMessage),
                      dismissButton: .default(Text("Retry"), action: resetFlow))
            }
        }
    }
    
    func verifyPin() {
        guard let combinedData = UserDefaults.standard.data(forKey: "encryptedPin") else {
            failureMessage = "No stored PIN found. Please reinstall the app."
            showFailureAlert = true
            return
        }

        do {
            let key = try KeychainHelper.shared.getKey()

            let sealedBox = try AES.GCM.SealedBox(combined: combinedData)
            let decryptedData = try AES.GCM.open(sealedBox, using: key)
            let decryptedPinString = String(data: decryptedData, encoding: .utf8) ?? ""
            let storedPin = decryptedPinString.components(separatedBy: "-")
            
            if pinInput == storedPin {
                onUnlockSuccess()
            } else {
                failureMessage = "PIN incorrect."
                showFailureAlert = true
            }
        } catch {
            failureMessage = "Decryption error."
            showFailureAlert = true
        }
    }

    func resetFlow() {
        biometricPassed = false
        pinInput = []
    }
}

struct BiometricAuthView: View {
    var onSuccess: () -> Void
    var onFail: () -> Void
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "lock.circle.dotted")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 4)
                .foregroundColor(.white)

            Text("Use Face ID or Touch ID")
                .font(.title2)
                .foregroundStyle(.white)

            Button(action: authenticate) {
                Text("Authenticate")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.white.opacity(0.2))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.4), lineWidth: 1)
                    )
            }
        }
        .padding()
    }
    
    func authenticate() {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: "Unlock your diary") { success, _ in
                DispatchQueue.main.async {
                    success ? onSuccess() : onFail()
                }
            }
        } else {
            onFail()
        }
    }
}

