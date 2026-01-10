import SwiftUI

/// The Vulpino app icon - a geometric fox in the Vignelli tradition
/// Minimal, typographic, black on cream
struct AppIconView: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            // Background - warm cream
            Color(red: 0.98, green: 0.97, blue: 0.94)

            // Geometric fox face
            VStack(spacing: 0) {
                // Ears
                HStack(spacing: size * 0.15) {
                    // Left ear
                    Triangle()
                        .fill(Color.black)
                        .frame(width: size * 0.22, height: size * 0.28)

                    // Right ear
                    Triangle()
                        .fill(Color.black)
                        .frame(width: size * 0.22, height: size * 0.28)
                }

                // Face (rounded square)
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(Color.black)
                    .frame(width: size * 0.55, height: size * 0.4)
                    .overlay(
                        // Eyes - two dots
                        HStack(spacing: size * 0.15) {
                            Circle()
                                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                                .frame(width: size * 0.08, height: size * 0.08)
                            Circle()
                                .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                                .frame(width: size * 0.08, height: size * 0.08)
                        }
                        .offset(y: -size * 0.06)
                    )
                    .overlay(
                        // Nose - small triangle pointing down
                        Triangle()
                            .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                            .frame(width: size * 0.08, height: size * 0.06)
                            .rotationEffect(.degrees(180))
                            .offset(y: size * 0.08)
                    )
                    .offset(y: -size * 0.05)
            }
            .offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

/// Simple triangle shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview("App Icon") {
    VStack(spacing: 20) {
        AppIconView(size: 180)
            .clipShape(RoundedRectangle(cornerRadius: 40))

        AppIconView(size: 60)
            .clipShape(RoundedRectangle(cornerRadius: 13))
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}

#Preview("Icon Export") {
    AppIconView(size: 1024)
}
