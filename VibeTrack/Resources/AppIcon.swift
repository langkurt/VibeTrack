import SwiftUI

// Generate app icon programmatically
struct AppIconView: View {
    var body: some View {
        ZStack {
            // Gradient Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.6, green: 0.2, blue: 0.8), // Purple
                    Color(red: 0.9, green: 0.2, blue: 0.3)  // Red
                ]),
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            )
            
            // Metallic V
            Text("V")
                .font(.system(size: 400, weight: .heavy, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(white: 0.9),
                            Color(white: 0.7),
                            Color(white: 0.5),
                            Color(white: 0.7),
                            Color(white: 0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                .shadow(color: .purple.opacity(0.5), radius: 20, x: 0, y: 0)
                .overlay(
                    Text("V")
                        .font(.system(size: 400, weight: .heavy, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear,
                                    Color.white.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
        }
        .frame(width: 1024, height: 1024)
    }
}

// Use this to export the icon as an image
struct AppIconExporter: View {
    var body: some View {
        AppIconView()
            .onAppear {
                // This will help you visualize the icon
                // To actually export, you'll need to take a screenshot
                // or use a rendering method
            }
    }
}
