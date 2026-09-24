import SwiftUI
import AppKit

// Mirror of VulpinoApp/Sources/Views/AppIconView.swift so the exported icon
// matches the app's own rendering exactly. No transparency (iOS icons forbid
// alpha) and no rounded corners in the asset (the OS masks them).

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

struct AppIconView: View {
    let size: CGFloat
    var body: some View {
        ZStack {
            Color(red: 0.98, green: 0.97, blue: 0.94)
            VStack(spacing: 0) {
                HStack(spacing: size * 0.15) {
                    Triangle().fill(Color.black).frame(width: size * 0.22, height: size * 0.28)
                    Triangle().fill(Color.black).frame(width: size * 0.22, height: size * 0.28)
                }
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(Color.black)
                    .frame(width: size * 0.55, height: size * 0.4)
                    .overlay(
                        HStack(spacing: size * 0.15) {
                            Circle().fill(Color(red: 0.98, green: 0.97, blue: 0.94)).frame(width: size * 0.08, height: size * 0.08)
                            Circle().fill(Color(red: 0.98, green: 0.97, blue: 0.94)).frame(width: size * 0.08, height: size * 0.08)
                        }.offset(y: -size * 0.06)
                    )
                    .overlay(
                        Triangle().fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                            .frame(width: size * 0.08, height: size * 0.06)
                            .rotationEffect(.degrees(180)).offset(y: size * 0.08)
                    )
                    .offset(y: -size * 0.05)
            }.offset(y: size * 0.02)
        }
        .frame(width: size, height: size)
    }
}

MainActor.assumeIsolated {
    let px: CGFloat = 1024
    let renderer = ImageRenderer(content: AppIconView(size: px).frame(width: px, height: px))
    renderer.scale = 1.0
    guard let cg = renderer.cgImage else { fputs("render failed\n", stderr); exit(1) }
    let rep = NSBitmapImageRep(cgImage: cg)
    rep.size = NSSize(width: px, height: px)
    guard let data = rep.representation(using: .png, properties: [:]) else { fputs("png encode failed\n", stderr); exit(1) }
    let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "app-icon-1024.png"
    do { try data.write(to: URL(fileURLWithPath: out)) } catch { fputs("write failed: \(error)\n", stderr); exit(1) }
    print("wrote \(out) (\(cg.width)x\(cg.height))")
}
