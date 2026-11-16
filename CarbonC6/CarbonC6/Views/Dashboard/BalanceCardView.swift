import SwiftUI

/// Card "Saldo": saldo atual em carrossel com a aba de Pontos,
/// multiplicador em destaque e ação para o extrato.
struct BalanceCardView: View {
    let account: Account
    let isHidden: Bool
    var onToggleVisibility: () -> Void
    var onOpenStatement: () -> Void
    var onOpenHelp: () -> Void

    @State private var selectedPage: Int = DebugHarness.initialBalancePage
    @State private var dragOffset: CGFloat = 0

    private let innerCardHeight: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.leading, 16)
                .padding(.trailing, 12)
                .padding(.top, 15)
                .padding(.bottom, 17)

            GeometryReader { proxy in
                let cardWidth = max(proxy.size.width - 32, 0)
                HStack(spacing: 16) {
                    balanceCard.frame(width: cardWidth)
                    pointsCard.frame(width: cardWidth)
                }
                .frame(width: cardWidth * 2 + 16, alignment: .leading)
                .offset(x: -CGFloat(selectedPage) * (cardWidth + 16) + dragOffset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .animation(.spring(response: 0.42, dampingFraction: 0.88), value: selectedPage)
            }
            .frame(height: innerCardHeight, alignment: .leading)
            .clipped()
            .overlay(alignment: .leading) {
                if selectedPage == 0 { peekHint(isTrailing: false) }
            }
            .overlay(alignment: .trailing) {
                if selectedPage == 0 { peekHint(isTrailing: true) }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 12)
                    .onChanged { value in
                        dragOffset = value.translation.width * 0.55
                    }
                    .onEnded { value in
                        let threshold: CGFloat = -50
                        let projected = value.translation.width + value.predictedEndTranslation.width * 0.3
                        var next = selectedPage
                        if projected < threshold { next = min(selectedPage + 1, 1) }
                        if projected > -threshold { next = max(selectedPage - 1, 0) }
                        if next != selectedPage { HapticService.selection() }
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            dragOffset = 0
                            selectedPage = next
                        }
                    }
            )

            pageIndicator
                .padding(.horizontal, 28)
                .padding(.top, 12)
                .padding(.bottom, 14)
        }
        .background(
            RoundedRectangle(cornerRadius: CarbonMetrics.cardRadius, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: CarbonMetrics.cardRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.035),
                                    Color(hex: 0x1B1B1B).opacity(0.96)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: CarbonMetrics.cardRadius, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 0.8)
                )
        )
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Saldo")
                .font(CarbonFont.display(18))
                .foregroundStyle(CarbonTheme.textPrimary)
            Spacer()
            CarbonChipButton(
                title: isHidden ? "Exibir saldo" : "Ocultar saldo",
                action: onToggleVisibility
            )
        }
    }

    // MARK: - Cards internos

    private var balanceCard: some View {
        innerCard(isActive: selectedPage == 0) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        BrazilFlagBadge(size: 18)
                        Text("Saldo")
                            .font(CarbonFont.display(13.5))
                            .foregroundStyle(CarbonTheme.textSecondary)
                    }
                    .frame(height: 22)

                    amountText(FinanceFormat.currency(account.balance), hiddenMask: "R$ ••••,••")
                        .padding(.top, 11)
                }
                .padding(.leading, 18)
                .padding(.trailing, 12)
                .padding(.top, 15)

                Spacer(minLength: 6)

                footerRow(title: "Extrato", showsChevron: true, action: onOpenStatement)
            }
        }
    }

    private var pointsCard: some View {
        innerCard(isActive: selectedPage == 1) {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(CarbonTheme.accent)
                            .frame(width: 18, height: 18)
                        Text("Pontos")
                            .font(CarbonFont.display(13.5))
                            .foregroundStyle(CarbonTheme.textSecondary)
                    }
                    .frame(height: 22)

                    amountText(Self.pointsText(account.points), hiddenMask: "••• pts")
                        .padding(.top, 11)

                    Text("Soma dos valores × valores")
                        .font(CarbonFont.display(12.5))
                        .foregroundStyle(CarbonTheme.textSecondary)
                        .lineLimit(1)
                        .padding(.top, 1)
                }
                .padding(.leading, 18)
                .padding(.trailing, 12)
                .padding(.top, 15)

                Spacer(minLength: 6)

                footerRow(title: "Como funciona", showsChevron: false, action: onOpenHelp)
            }
        }
    }

    private func innerCard<Content: View>(isActive: Bool, @ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: CarbonMetrics.innerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: 0x202020), Color(hex: 0x1C1C1C)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CarbonMetrics.innerRadius, style: .continuous)
                    .strokeBorder(
                        isActive ? Color.white.opacity(0.10) : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: CarbonMetrics.innerRadius, style: .continuous))
            .accessibilityHidden(!isActive)
    }

    private func footerRow(title: String, showsChevron: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Text(title)
                    .font(CarbonFont.display(14))
                    .foregroundStyle(CarbonTheme.accent)
                Spacer(minLength: 4)
                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(CarbonTheme.accent)
                }
            }
            .padding(.leading, 18)
            .padding(.trailing, 14)
            .frame(height: 40)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(HapticButtonStyle(style: .light, scale: 0.99))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.white.opacity(0.09))
                .frame(height: 0.7)
        }
        .frame(height: 48)
    }

    // MARK: - Valor com toggle de ocultar

    private func amountText(_ text: String, hiddenMask: String) -> some View {
        Text(isHidden ? hiddenMask : text)
            .font(CarbonFont.display(22.5))
            .foregroundStyle(CarbonTheme.textPrimary)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .contentTransition(.numericText())
            .blur(radius: isHidden ? 0.6 : 0)
            .animation(.easeInOut(duration: 0.22), value: isHidden)
            .animation(.snappy, value: text)
            .accessibilityLabel(isHidden ? "Valor oculto" : text)
    }

    /// Dica visual de que existe mais conteúdo (estilo carrossel).
    private func peekHint(isTrailing: Bool) -> some View {
        LinearGradient(
            colors: isTrailing
                ? [Color.clear, Color(hex: 0x1D1D1D)]
                : [Color(hex: 0x1D1D1D), Color.clear],
            startPoint: .leading,
            endPoint: .trailing
        )
        .frame(width: 14)
        .allowsHitTesting(false)
    }

    // MARK: - Indicadores

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { index in
                Capsule()
                    .fill(index == selectedPage ? CarbonTheme.textPrimary : Color.white.opacity(0.22))
                    .frame(width: index == selectedPage ? 16 : 6, height: 4)
                    .contentShape(Rectangle().inset(by: -8))
                    .onTapGesture {
                        guard selectedPage != index else { return }
                        HapticService.selection()
                        withAnimation(.spring(response: 0.42, dampingFraction: 0.88)) {
                            selectedPage = index
                        }
                    }
            }
            Spacer()
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: selectedPage)
        .accessibilityElement()
        .accessibilityLabel("Painel \(selectedPage + 1) de 2")
    }

    static func pointsText(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return (formatter.string(from: value as NSDecimalNumber) ?? "0,0") + " pts"
    }
}

#if DEBUG
#Preview("BalanceCard") {
    let account = PreviewFactory.account()
    return ZStack {
        CarbonTheme.background.ignoresSafeArea()
        BalanceCardView(
            account: account,
            isHidden: false,
            onToggleVisibility: {},
            onOpenStatement: {},
            onOpenHelp: {}
        )
        .padding(.horizontal, 16)
    }
}
#endif
