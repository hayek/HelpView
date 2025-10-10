import SwiftUI

struct AppleIntelligenceLoader: View {
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    private let gradient = LinearGradient(
        colors: [
            Color(red: 0.6, green: 0.4, blue: 1.0),  // Purple
            Color(red: 0.4, green: 0.6, blue: 1.0),  // Blue
            Color(red: 1.0, green: 0.4, blue: 0.8),  // Pink
            Color(red: 1.0, green: 0.5, blue: 0.3),  // Orange
            Color(red: 0.6, green: 0.4, blue: 1.0),  // Purple (loop)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    var body: some View {
        ZStack {
            // Outer rotating ring
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: [
                            Color(red: 0.6, green: 0.4, blue: 1.0),
                            Color(red: 0.4, green: 0.6, blue: 1.0),
                            Color(red: 1.0, green: 0.4, blue: 0.8),
                            Color(red: 1.0, green: 0.5, blue: 0.3),
                            Color(red: 0.6, green: 0.4, blue: 1.0),
                        ],
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))

            // Inner pulsing circle
            Circle()
                .fill(gradient)
                .frame(width: 16, height: 16)
                .scaleEffect(scale)
                .opacity(0.8)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.3
            }
        }
    }
}

struct AppleIntelligenceMiniLoader: View {
    @State private var rotation: Double = 0

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.7)
            .stroke(
                AngularGradient(
                    colors: [
                        Color(red: 0.6, green: 0.4, blue: 1.0),
                        Color(red: 0.4, green: 0.6, blue: 1.0),
                        Color(red: 1.0, green: 0.4, blue: 0.8),
                        Color(red: 1.0, green: 0.5, blue: 0.3),
                        Color(red: 0.6, green: 0.4, blue: 1.0),
                    ],
                    center: .center,
                    startAngle: .degrees(0),
                    endAngle: .degrees(360)
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
            .frame(width: 16, height: 16)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}
