import SwiftUI

// MARK: - Glifos vetoriais da barra de ações e da tab bar

/// Código de barras com colchetes de leitura (ação "Pagar").
struct BarcodeReadGlyph: View {
    var lineWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            HStack(spacing: 2.6) {
                ForEach(Array(bars.enumerated()), id: \.offset) { _, width in
                    Capsule().fill(.white).frame(width: width)
                }
            }
            .padding(.horizontal, 5.5)
            .padding(.vertical, 6.5)
            BracketGlyph()
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        }
    }

    private var bars: [CGFloat] {
        [1.6, 1.1, 1.6, 1.1, 3.0, 1.1, 1.6, 1.1]
    }
}

private struct BracketGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let arm = rect.width * 0.22
        let inset = 1.5
        let left = rect.minX + inset
        let right = rect.maxX - inset
        let top = rect.minY + inset
        let bottom = rect.maxY - inset
        p.move(to: CGPoint(x: left + arm, y: top))
        p.addLine(to: CGPoint(x: left, y: top))
        p.addLine(to: CGPoint(x: left, y: top + arm))
        p.move(to: CGPoint(x: left, y: bottom - arm))
        p.addLine(to: CGPoint(x: left, y: bottom))
        p.addLine(to: CGPoint(x: left + arm, y: bottom))
        p.move(to: CGPoint(x: right - arm, y: top))
        p.addLine(to: CGPoint(x: right, y: top))
        p.addLine(to: CGPoint(x: right, y: top + arm))
        p.move(to: CGPoint(x: right, y: bottom - arm))
        p.addLine(to: CGPoint(x: right, y: bottom))
        p.addLine(to: CGPoint(x: right - arm, y: bottom))
        return p
    }
}

/// Losango Pix (contorno com furo) — usado no card de atalho.
struct PixGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addRoundedDiamond(center: c, radius: r * 0.98, corner: r * 0.36)
        p.addRoundedDiamond(center: c, radius: r * 0.52, corner: r * 0.20)
        return p
    }
}

/// Losango Pix sólido com furo central (ícone das ações rápidas).
struct PixSolidGlyph: View {
    var body: some View {
        ZStack {
            PixSolidShape()
                .fill(.white)
                .frame(width: 28, height: 28)
            RoundedRectangle(cornerRadius: 2.4, style: .continuous)
                .fill(CarbonTheme.surfaceMuted)
                .frame(width: 7.5, height: 7.5)
                .rotationEffect(.degrees(45))
        }
        .frame(width: 28, height: 28)
    }
}

private struct PixSolidShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = min(rect.width, rect.height) / 2
        p.addRoundedDiamond(center: c, radius: r * 0.98, corner: r * 0.36)
        return p
    }
}

private extension Path {
    /// Adiciona um losango com cantos levemente arredondados.
    mutating func addRoundedDiamond(center: CGPoint, radius: CGFloat, corner: CGFloat) {
        let top = CGPoint(x: center.x, y: center.y - radius)
        let right = CGPoint(x: center.x + radius, y: center.y)
        let bottom = CGPoint(x: center.x, y: center.y + radius)
        let left = CGPoint(x: center.x - radius, y: center.y)
        let t = corner / radius
        func lerp(_ a: CGPoint, _ b: CGPoint, _ amount: CGFloat) -> CGPoint {
            CGPoint(x: a.x + (b.x - a.x) * amount, y: a.y + (b.y - a.y) * amount)
        }
        move(to: lerp(top, right, t))
        addLine(to: lerp(right, top, t))
        addQuadCurve(to: lerp(right, bottom, t), control: right)
        addLine(to: lerp(bottom, right, t))
        addQuadCurve(to: lerp(bottom, left, t), control: bottom)
        addLine(to: lerp(left, bottom, t))
        addQuadCurve(to: lerp(left, top, t), control: left)
        addLine(to: lerp(top, left, t))
        addQuadCurve(to: lerp(top, right, t), control: top)
        closeSubpath()
    }
}

/// Escudo com cadeado (ação "Segurança").
struct ShieldLockGlyph: View {
    var lineWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            ShieldShape()
                .stroke(.white, style: StrokeStyle(lineWidth: lineWidth, lineJoin: .round))
            VStack(spacing: 0) {
                // Haste do cadeado
                ZStack {
                    Capsule()
                        .stroke(.white, lineWidth: lineWidth)
                        .frame(width: 7.5, height: 6.5)
                        .offset(y: 1.5)
                }
                .frame(width: 7.5, height: 5)
                .clipped()
                RoundedRectangle(cornerRadius: 1.6, style: .continuous)
                    .fill(.white)
                    .frame(width: 9.5, height: 7)
            }
            .offset(y: 1)
        }
    }
}

private struct ShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.06))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.06, y: rect.minY + h * 0.22))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.06, y: rect.minY + h * 0.47))
        p.addCurve(
            to: CGPoint(x: rect.midX, y: rect.maxY - h * 0.04),
            control1: CGPoint(x: rect.maxX - w * 0.06, y: rect.minY + h * 0.70),
            control2: CGPoint(x: rect.midX + w * 0.24, y: rect.maxY - h * 0.14)
        )
        p.addCurve(
            to: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + h * 0.47),
            control1: CGPoint(x: rect.midX - w * 0.24, y: rect.maxY - h * 0.14),
            control2: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + h * 0.70)
        )
        p.addLine(to: CGPoint(x: rect.minX + w * 0.06, y: rect.minY + h * 0.22))
        p.closeSubpath()
        return p
    }
}

/// Três linhas com knobs (ação "Limites").
struct SlidersGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        let rows: [(CGFloat, CGFloat)] = [(0.20, 0.66), (0.50, 0.34), (0.80, 0.62)]
        for (yRatio, knob) in rows {
            let y = rect.minY + h * yRatio
            p.move(to: CGPoint(x: rect.minX + w * 0.02, y: y))
            p.addLine(to: CGPoint(x: rect.minX + w * 0.98, y: y))
            let r = w * 0.095
            let cx = rect.minX + w * knob
            p.addEllipse(in: CGRect(x: cx - r, y: y - r, width: r * 2, height: r * 2))
        }
        return p
    }
}

/// Traço + knobs preenchidos (knob com miolo vazado para o "ticket" da referência).
struct SlidersIcon: View {
    var lineWidth: CGFloat = 1.6

    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                VStack(spacing: 3.4) {
                    Rectangle().fill(.white).frame(height: 1.4)
                    Rectangle().fill(.white).frame(height: 1.4)
                    Rectangle().fill(.white).frame(height: 1.4)
                }
                .frame(maxHeight: .infinity)
            }
            .padding(.vertical, 2)
            VStack(spacing: 0) {
                GeometryReader { geo in
                    let rows: [CGFloat] = [0.66, 0.34, 0.62]
                    let h = geo.size.height / 3
                    ForEach(Array(rows.enumerated()), id: \.offset) { index, x in
                        ZStack {
                            Circle().fill(.white).frame(width: 7.5, height: 7.5)
                            Circle().fill(Color(hex: 0x272727)).frame(width: 3.2, height: 3.2)
                        }
                        .position(x: geo.size.width * x, y: h * (CGFloat(index) + 0.5))
                    }
                }
            }
        }
    }
}

/// Prédio com base (ícone do card "Complete sua experiência").
struct InstitutionGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: rect.minX + w * 0.08, y: rect.minY + h * 0.26))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.minY + h * 0.06))
        p.addLine(to: CGPoint(x: rect.maxX - w * 0.08, y: rect.minY + h * 0.26))
        p.closeSubpath()
        for x in [0.18, 0.41, 0.64, 0.87] {
            p.move(to: CGPoint(x: rect.minX + w * x, y: rect.minY + h * 0.38))
            p.addLine(to: CGPoint(x: rect.minX + w * x, y: rect.minY + h * 0.70))
        }
        p.addRoundedRect(
            in: CGRect(x: rect.minX + w * 0.10, y: rect.minY + h * 0.78, width: w * 0.80, height: h * 0.12),
            cornerSize: CGSize(width: h * 0.06, height: h * 0.06)
        )
        return p
    }
}

// MARK: - Bandeira do Brasil (vetor)

struct BrazilFlagBadge: View {
    var size: CGFloat = 20

    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x1E9E4B))
            DiamondShape()
                .fill(Color(hex: 0xF4D03F))
                .frame(width: size * 0.66, height: size * 0.66)
            Circle()
                .fill(Color(hex: 0x1B3E9E))
                .frame(width: size * 0.38, height: size * 0.38)
            Capsule()
                .fill(Color.white)
                .frame(width: size * 0.40, height: size * 0.07)
                .rotationEffect(.degrees(-15))
                .mask(Circle().frame(width: size * 0.38, height: size * 0.38))
        }
        .frame(width: size, height: size)
    }

    private struct DiamondShape: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
            p.closeSubpath()
            return p
        }
    }
}

/// Selo "C6 Átomos" com circunflexo (como na referência).
struct CaretBadge: View {
    var size: CGFloat = 18

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.10))
                .frame(width: size * 0.9, height: size * 0.9)
            Image(systemName: "chevron.up")
                .font(.system(size: size * 0.40, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
                .offset(y: size * 0.04)
        }
        .frame(width: size, height: size)
    }
}

/// Selo "C6 Átomos".
struct AtomBadge: View {
    var size: CGFloat = 18

    var body: some View {
        Image(systemName: "atom")
            .font(.system(size: size * 0.66, weight: .semibold))
            .foregroundStyle(Color(hex: 0x9B8BFF))
            .frame(width: size, height: size)
            .background(Circle().fill(Color(hex: 0x2C2635)))
    }
}

// MARK: - Ícone de categoria

struct CategoryIconView: View {
    let category: TransactionCategory
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: CategoryIconView.symbol(for: category))
            .font(.system(size: size * 0.40, weight: .semibold))
            .foregroundStyle(category.swatch.first ?? .white)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                (category.swatch.last ?? .white).opacity(0.30),
                                (category.swatch.first ?? .white).opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.32, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    /// SF Symbol de cada categoria (compartilhado entre lista e seletor).
    static func symbol(for category: TransactionCategory) -> String {
        switch category {
        case .alimentacao: return "fork.knife"
        case .transporte: return "car.fill"
        case .moradia: return "house.fill"
        case .lazer: return "popcorn.fill"
        case .saude: return "cross.case.fill"
        case .educacao: return "book.fill"
        case .compras: return "bag.fill"
        case .assinaturas: return "repeat"
        case .cashback: return "gift.fill"
        case .outros: return "ellipsis.circle.fill"
        }
    }
}
