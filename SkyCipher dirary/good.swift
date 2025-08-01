//
//  good.swift
//  SkyCipher dirary
//
//  Created by Owner on 7/29/25.
//

import SwiftUI

struct PinInputView: View {
    // User's current PIN input (symbol names)
    @Binding var pin: [String]
    
    // Called once PIN input is complete
    var onComplete: () -> Void
    
    // Customize your symbolic keypad here
    private let symbols = ["moon", "rainbow", "flame", "bolt", "mountain.2", "hare", "bird", "lizard", "pawprint", "tree", "atom", "figure"]
    private let pinLength = 6
    
    var body: some View {
        VStack(spacing: 30) {
            
            Text("Enter Your Skycipher PIN")
                .font(.title2.bold())
                .foregroundColor(.white)
                .padding(.top, 20)
            
            // PIN Preview Display
            HStack(spacing: 18) {
                ForEach(0..<pinLength, id: \.self) { index in
                    if index < pin.count {
                        Image(systemName: pin[index])
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.pink)
                            .padding(6)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    } else {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 2)
                            .frame(width: 40, height: 40)
                    }
                }
            }
            .padding(.horizontal)
            
            // Grid Keypad
            let columns = [GridItem(.adaptive(minimum: 60))]
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(symbols, id: \.self) { symbol in
                    Button(action: {
                        if pin.count < pinLength {
                            pin.append(symbol)
                            if pin.count == pinLength {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    onComplete()
                                }
                            }
                        }
                    }) {
                        Image(systemName: symbol)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 32, height: 32)
                            .padding()
                            .background(Color.pink.opacity(0.15))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Color.pink.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            // Delete Button
            if !pin.isEmpty {
                Button(action: {
                    _ = pin.popLast()
                }) {
                    Label("Delete", systemImage: "delete.left")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 24)
                        .background(Color.red.opacity(0.2))
                        .clipShape(Capsule())
                        .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
                }
                .padding(.top, 10)
            }
        }
        .padding(.bottom, 30)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(colors: [Color.black, Color.purple.opacity(0.7)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
    }
}
