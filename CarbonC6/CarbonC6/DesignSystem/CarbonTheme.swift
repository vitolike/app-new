import SwiftUI

extension Color {
    /// `Color(hex: 0x1B1B1B)` — helper para a paleta "carbon" do app.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Paleta extraída pixel a pixel do layout de referência.
enum CarbonTheme {
    // Superfícies
    static let background = Color(hex: 0x111111)
    static let surface = Color(hex: 0x1B1B1B)
    static let surfaceElevated = Color(hex: 0x1F1F1F)
    static let surfaceFill = Color(hex: 0x242424)
    static let surfaceMuted = Color(hex: 0x272727)
    static let surfaceSheet = Color(hex: 0x161616)

    // Traços
    static let hairline = Color(hex: 0x333333)
    static let border = Color(hex: 0x3D3D3D)

    // Texto
    static let textPrimary = Color(hex: 0xF5F5F5)
    static let textSecondary = Color(hex: 0xA8A8A8)
    static let textTertiary = Color(hex: 0x767676)

    // Acento (azul C6)
    static let accent = Color(hex: 0x5499F5)
    static let accentSoft = Color(hex: 0x1F2B3B)
    static let accentGlow = Color(hex: 0x3E8FF7)

    // Semântica
    static let positive = Color(hex: 0x4ED9A5)
    static let negative = Color(hex: 0xF0719A)
    static let warning = Color(hex: 0xF2C14E)

    // Lente C6 Átomos
    static let lensCyan = Color(hex: 0x3FBFEA)
    static let lensBlue = Color(hex: 0x2A47D0)
}

/// Métricas de espaçamento e raios (cantos contínuos) do app.
enum CarbonMetrics {
    static let horizontalPadding: CGFloat = 16
    static let sectionSpacing: CGFloat = 20
    static let cardRadius: CGFloat = 20
    static let innerRadius: CGFloat = 16
    static let tileRadius: CGFloat = 18
    static let chipRadius: CGFloat = 12
    static let buttonHeight: CGFloat = 54
}

/// Tipografia SF Pro.
enum CarbonFont {
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .regular, design: .default)
    }

    static func rounded(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

/// Anel estilo "lente" C6 Átomos desenhado 100% em SwiftUI.
struct LensMark: View {
    var size: CGFloat = 32
    var innerRing: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: 0x1D4ED8),
                            Color(hex: 0x152C82),
                            Color(hex: 0x0B1338)
                        ],
                        center: UnitPoint(x: 0.42, y: 0.38),
                        startRadius: 0,
                        endRadius: size * 0.55
                    )
                )
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [CarbonTheme.lensCyan, CarbonTheme.lensBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: max(1.5, size * 0.07)
                )
            if innerRing {
                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color(hex: 0x7FE1FF), CarbonTheme.lensBlue.opacity(0.85)],
                            startPoint: .bottomLeading,
                            endPoint: .topTrailing
                        ),
                        lineWidth: max(1, size * 0.035)
                    )
                    .padding(size * 0.13)
            }
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
                .padding(size * 0.2)
        }
        .frame(width: size, height: size)
        .overlay {
            Circle()
                .strokeBorder(Color(hex: 0x2B2B2B), lineWidth: 1)
                .padding(-1)
        }
        .shadow(color: CarbonTheme.lensCyan.opacity(0.35), radius: size * 0.18, y: size * 0.04)
    }
}

/// Marca "C6 Carbon" — reprodução vetorial (funciona no Preview, sem assets).
struct CarbonWordmark: View {
    var height: CGFloat = 22

    var body: some View {
        HStack(alignment: .center, spacing: height * 0.24) {
            HStack(spacing: -height * 0.16) {
                Circle()
                    .stroke(Color.white, lineWidth: height * 0.32)
                    .frame(width: height * 0.78, height: height * 0.78)
                Circle()
                    .fill(Color.white)
                    .frame(width: height * 0.58, height: height * 0.58)
            }
            Text("Carbon")
                .font(.system(size: height * 1.08, weight: .light, design: .default))
                .foregroundStyle(Color.white)
                .tracking(-0.2)
                .offset(y: -height * 0.03)
        }
    }
}

extension View {
    /// Cantos contínuos (estilo Apple) com preenchimento e borda opcional.
    func carbonCard(
        radius: CGFloat = CarbonMetrics.cardRadius,
        fill: Color = CarbonTheme.surface,
        stroke: Color = Color.clear,
        lineWidth: CGFloat = 1
    ) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(fill)
                .overlay(
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .strokeBorder(stroke, lineWidth: lineWidth)
                )
        )
    }

    /// Sombra suave característica dos cards flutuantes.
    func carbonShadow() -> some View {
        shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 10)
    }
}

/// Botão com feedback háptico embutido + efeito de escala (alvo mínimo de 44pt).
struct HapticButtonStyle: ButtonStyle {
    var style: UIImpactFeedbackGenerator.FeedbackStyle = .medium
    var scale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { HapticService.impact(style) }
            }
    }
}
