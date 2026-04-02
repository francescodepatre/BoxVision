//
//  SplashView.swift
//  BoxVision
//

import SwiftUI

struct SplashView: View {

    @State private var phase: Int = 0
    // 0 = dot fermi
    // 1 = dot che rimbalzano
    // 2 = dot che convergono al centro
    // 3 = testo che appare

    @State private var offsets: [CGFloat] = [0, 0, 0, 0]
    @State private var dotsVisible = true
    @State private var textOpacity: Double = 0
    @State private var textScale: CGFloat = 0.7
    @State private var dotScale: CGFloat = 1.0
    @State private var dotSpacing: CGFloat = 12

    let colors: [Color] = [.black, .black, .black, .black]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            // Testo sotto
            Text("Box Vision")
                .font(.system(size: 40, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
                .opacity(textOpacity)
                .scaleEffect(textScale)

            // Dot sopra
            if dotsVisible {
                HStack(spacing: dotSpacing) {
                    ForEach(0..<4, id: \.self) { i in
                        Circle()
                            .fill(colors[i])
                            .frame(width: 14, height: 14)
                            .scaleEffect(dotScale)
                            .offset(y: offsets[i])
                    }
                }
            }
        }
        .onAppear { startAnimation() }
    }

    func startAnimation() {

        // Fase 1: rimbalzo sequenziale (bounce)
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.25)) {
                    offsets[i] = -18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        offsets[i] = 0
                    }
                }
            }
        }

        // Ripeti il bounce una seconda volta
        for i in 0..<4 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.7 + Double(i) * 0.15) {
                withAnimation(.easeOut(duration: 0.25)) {
                    offsets[i] = -18
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation(.easeIn(duration: 0.25)) {
                        offsets[i] = 0
                    }
                }
            }
        }

        // Fase 2: i dot si avvicinano e rimpiccioliscono
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.easeInOut(duration: 0.35)) {
                dotSpacing = 2
                dotScale = 0.6
            }
        }

        // Fase 3: i dot scompaiono, il testo appare
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                dotScale = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                dotsVisible = false
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    textOpacity = 1
                    textScale = 1.0
                }
            }
        }
    }
}

#Preview {
    SplashView()
}
