//
//  shred.swift
//  SkyCipher dirary
//
//  Created by Owner on 8/6/25.
//

import SwiftUI

struct ConfessionShredderView: View {
    @State private var confession = ""
    @State private var isShredding = false
    @State private var showToast = false
    @Namespace private var animation

    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                Text("Write & Shred")
                    .font(.largeTitle.bold())
                    .foregroundStyle(.primary)

                ZStack {
                    if !isShredding {
                        TextEditor(text: $confession)
                            .padding()
                            .frame(height: 250)
                            .background(Color.white.opacity(0.1))
                            .cornerRadius(16)
                            .matchedGeometryEffect(id: "paper", in: animation)
                    } else {
                        // Fake shred effect: animate the text collapsing
                        VStack(spacing: 4) {
                            ForEach(Array(confession.enumerated()), id: \.offset) { index, char in
                                Text(String(char))
                                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                                    .opacity(0.8)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                                    .animation(.easeInOut(duration: 0.6).delay(Double(index) * 0.01), value: isShredding)
                            }
                        }
                        .frame(height: 250)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(16)
                        .matchedGeometryEffect(id: "paper", in: animation)
                    }
                }

                Button(action: shred) {
                    Label("Shred", systemImage: "trash")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(confession.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()

            if showToast {
                VStack {
                    Spacer()
                    Text("🗑️ Shredded")
                        .padding()
                        .background(Color.accentColor)
                        .cornerRadius(12)
                        .foregroundColor(.white)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
                .animation(.easeInOut, value: showToast)
            }
        }
    }

    func shred() {
        withAnimation {
            isShredding = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                confession = ""
                isShredding = false
                showToast = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation {
                    showToast = false
                }
            }
        }
    }
}

