import SwiftUI

struct AdaptiveGradientBackground: View {
    enum Intensity {
        case full      // Main recording view
        case subtle    // Charts view
        case minimal   // Other views that need just a hint
    }
    
    let intensity: Intensity
    
    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: gradientColors),
            startPoint: .topTrailing,
            endPoint: .bottomLeading
        )
        .ignoresSafeArea()
    }
    
    private var gradientColors: [Color] {
        switch intensity {
        case .full:
            return [
                Color(red: 0.6, green: 0.2, blue: 0.8), // Purple
                Color(red: 0.9, green: 0.2, blue: 0.3)  // Red
            ]
        case .subtle:
            return [
                Color(red: 0.6, green: 0.2, blue: 0.8).opacity(0.6),
                Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.6)
            ]
        case .minimal:
            return [
                Color(red: 0.6, green: 0.2, blue: 0.8).opacity(0.2),
                Color(red: 0.9, green: 0.2, blue: 0.3).opacity(0.2)
            ]
        }
    }
}

// Usage examples:
// AdaptiveGradientBackground(intensity: .full)     // Main recording
// AdaptiveGradientBackground(intensity: .subtle)   // Charts
// AdaptiveGradientBackground(intensity: .minimal)  // Lists
