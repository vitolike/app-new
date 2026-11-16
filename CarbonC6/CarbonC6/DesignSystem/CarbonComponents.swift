import SwiftUI

// MARK: - Header

/// Linha superior: avatar, saudação e wordmark.
struct CarbonHeaderView: View {
    let greeting: String

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Button {
                HapticService.impact(.light)
            } label: {
                Image(systemName: "person")
                    .font(.system(size: 21, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44, alignment: .leading)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Perfil")

            Text(greeting)
                .font(CarbonFont.display(17))
                .foregroundStyle(.white)
                .lineLimit(1)

            Spacer(minLength: 12)

            CarbonWordmark(height: 20)
                .accessibilityLabel("C6 Carbon")
        }
    }
}

// MARK: - Busca / Assistente

/// Chip de busca com a lente da assistente + ícones de ajuda, suporte e privacidade.
struct CarbonSearchBar: View {
    @Binding var text: String
    var onAssist: () -> Void
    var onNotifications: () -> Void
    var onPrivacy: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 12) {
                Button(action: onAssist) {
                    LensMark(size: 26)
                }
                .buttonStyle(HapticButtonStyle(style: .light, scale: 0.9))
                .accessibilityLabel("C6 Assistente")

                TextField("Posso te ajudar?", text: $text)
                    .focused($isFocused)
                    .font(CarbonFont.display(16))
                    .foregroundStyle(CarbonTheme.textPrimary)
                    .tint(CarbonTheme.accent)
                    .submitLabel(.search)
                    .onSubmit { if !text.isEmpty { HapticService.impact(.light) } }
            }
            .padding(.leading, 12)
            .padding(.trailing, 14)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(CarbonTheme.surfaceFill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8)
            )
            .layoutPriority(1)

            HStack(spacing: 0) {
                IconClusterButton(systemName: "questionmark.circle", label: "Ajuda") {
                    HapticService.impact(.light)
                }
                Divider().frame(height: 22).overlay(Color.white.opacity(0.22))
                IconClusterButton(systemName: "bubble.left", label: "Atendimento", badge: true, action: onNotifications)
                Divider().frame(height: 22).overlay(Color.white.opacity(0.22))
                IconClusterButton(systemName: "eye", label: "Privacidade", action: onPrivacy)
            }
            .padding(.leading, 4)
        }
    }
}

private struct IconClusterButton: View {
    let systemName: String
    let label: String
    var badge: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if badge {
                        Circle()
                            .fill(Color(hex: 0xF1646A))
                            .frame(width: 9, height: 9)
                            .offset(x: -9, y: 9)
                    }
                }
        }
        .buttonStyle(HapticButtonStyle(style: .light, scale: 0.9))
        .accessibilityLabel(label)
    }
}

// MARK: - Botões

/// Chip azul translúcido ("Exibir saldos", "Menu completo").
struct CarbonChipButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(CarbonFont.display(14.5))
                .foregroundStyle(CarbonTheme.accent)
                .padding(.horizontal, 13)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: CarbonMetrics.chipRadius, style: .continuous)
                        .fill(CarbonTheme.accent.opacity(0.11))
                )
                .contentShape(RoundedRectangle(cornerRadius: CarbonMetrics.chipRadius, style: .continuous))
        }
        .buttonStyle(HapticButtonStyle(style: .light))
    }
}

// MARK: - Tiles de ação

enum QuickAction: String, CaseIterable, Identifiable {
    case gasto, seguranca

    var id: String { rawValue }

    var title: String {
        switch self {
        case .gasto: return "Adicionar gasto"
        case .seguranca: return "Segurança"
        }
    }
}

/// Tile quadrado das ações rápidas (ícone vetorial + label).
struct QuickActionTile: View {
    let action: QuickAction
    var isPrimary: Bool = false
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 10) {
                glyph
                    .frame(width: 27, height: 27)
                    .padding(.top, 4)
                Text(action.title)
                    .font(CarbonFont.display(14.5))
                    .foregroundStyle(CarbonTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 92)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: CarbonMetrics.tileRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isPrimary
                                ? [CarbonTheme.accent.opacity(0.26), CarbonTheme.accent.opacity(0.10)]
                                : [CarbonTheme.surfaceMuted, Color(hex: 0x212121)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: CarbonMetrics.tileRadius, style: .continuous)
                    .strokeBorder(
                        isPrimary ? CarbonTheme.accent.opacity(0.45) : Color.white.opacity(0.05),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(HapticButtonStyle())
        .accessibilityLabel(action.title)
    }

    @ViewBuilder
    private var glyph: some View {
        switch action {
        case .gasto: Image(systemName: "plus").font(.system(size: 22, weight: .medium)).foregroundStyle(.white)
        case .seguranca: ShieldLockGlyph()
        }
    }
}

// MARK: - Tab bar flutuante (liquid glass)

enum CarbonTab: String, CaseIterable, Identifiable {
    case home, extrato, menu

    var id: String { rawValue }

    var title: String {
        switch self {
        case .home: return "Início"
        case .extrato: return "Extrato"
        case .menu: return "Menu"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house"
        case .extrato: return "list.bullet.rectangle"
        case .menu: return "ellipsis"
        }
    }
}

/// Tab bar translúcida flutuante com seleção em "pill" light-glass.
struct CarbonFloatingTabBar: View {
    @Binding var selection: CarbonTab
    @Namespace private var pillNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(CarbonTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 7)
        .background(
            ZStack {
                Capsule(style: .continuous)
                    .fill(.ultraThinMaterial)
                Capsule(style: .continuous)
                    .fill(Color(hex: 0x56565C).opacity(0.42))
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.07), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                Capsule(style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.20), Color.white.opacity(0.04)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 0.8
                    )
            }
            .environment(\.colorScheme, .dark)
        )
        .shadow(color: .black.opacity(0.5), radius: 24, y: 12)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    @ViewBuilder
    private func tabItem(_ tab: CarbonTab) -> some View {
        let isSelected = selection == tab
        Button {
            guard !isSelected else { return }
            HapticService.selection()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                selection = tab
            }
        } label: {
            VStack(spacing: 5) {
                icon(for: tab, isSelected: isSelected)
                    .frame(height: 26)
                if tab != .home || !isSelected {
                    Text(tab.title)
                        .font(CarbonFont.display(11.5))
                        .foregroundStyle(isSelected ? .white : CarbonTheme.textSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background {
                if isSelected {
                    ZStack {
                        Capsule(style: .continuous)
                            .fill(Color.white.opacity(0.06))
                        Capsule(style: .continuous)
                            .fill(.ultraThinMaterial)
                            .environment(\.colorScheme, .dark)
                    }
                    .environment(\.colorScheme, .dark)
                    .matchedGeometryEffect(id: "tab.pill", in: pillNamespace)
                }
            }
            .contentShape(Capsule(style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    private func icon(for tab: CarbonTab, isSelected: Bool) -> some View {
        Image(systemName: tab.icon)
            .font(.system(size: 21, weight: isSelected ? .medium : .regular))
            .foregroundStyle(.white)
            .opacity(isSelected ? 1 : 0.92)
    }
}

// MARK: - Linhas

/// Linha de gasto: valor, multiplicação por ele mesmo e crédito no saldo.
/// Deslize para a esquerda (ou toque e segure) para excluir.
struct TransactionRow: View {
    var transaction: Transaction
    var hidden: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            CategoryIconView(category: transaction.category)

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.nameLabel)
                    .font(CarbonFont.display(14.5))
                    .foregroundStyle(CarbonTheme.textPrimary)
                    .lineLimit(1)
                Text(summaryText)
                    .font(CarbonFont.display(11))
                    .foregroundStyle(CarbonTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(hidden ? "••••" : "+ " + FinanceFormat.currency(transaction.creditedAmount))
                    .font(CarbonFont.display(14.5))
                    .monospacedDigit()
                    .foregroundStyle(CarbonTheme.positive)
                    .contentTransition(.numericText())
                if let onDelete {
                    Button(role: .destructive, action: onDelete) {
                        Text("Excluir")
                            .font(CarbonFont.display(11).weight(.medium))
                            .foregroundStyle(CarbonTheme.negative)
                            .padding(.horizontal, 8)
                            .frame(height: 22)
                            .background(Capsule().fill(CarbonTheme.negative.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Excluir \(transaction.nameLabel)")
                }
            }
        }
        .padding(.vertical, 11)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(transaction.nameLabel)
        .accessibilityValue(hidden ? "Valor oculto" : summaryText)
    }

    private var summaryText: String {
        if hidden { return relativeTimestamp }
        return "\(transaction.amountLabel) × \(transaction.amountLabel) · \(relativeTimestamp)"
    }

    private var relativeTimestamp: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: transaction.date, relativeTo: .now)
    }
}

// MARK: - Toast de confirmação

struct ReceiptToast: View {
    let receipt: DashboardViewModel.Receipt
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(CarbonTheme.positive)
            VStack(alignment: .leading, spacing: 2) {
                Text(receipt.title)
                    .font(CarbonFont.display(14))
                    .foregroundStyle(.white)
                Text(receipt.detail)
                    .font(CarbonFont.display(12))
                    .foregroundStyle(CarbonTheme.textSecondary)
            }
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(CarbonTheme.textSecondary)
                    .frame(width: 30, height: 30)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(CarbonTheme.surface.opacity(0.55))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .padding(.horizontal, 16)
    }
}

// MARK: - Cabeçalho de sheet

struct SheetHeader: View {
    let title: String
    let subtitle: String?
    var onClose: () -> Void

    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(CarbonFont.display(19))
                    .foregroundStyle(.white)
                if let subtitle {
                    Text(subtitle)
                        .font(CarbonFont.display(13))
                        .foregroundStyle(CarbonTheme.textSecondary)
                }
            }
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(CarbonTheme.textSecondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(Color.white.opacity(0.07)))
            }
            .buttonStyle(HapticButtonStyle(style: .light))
            .accessibilityLabel("Fechar")
        }
    }
}

// MARK: - Botão primário

struct CarbonPrimaryButton: View {
    let title: String
    var systemImage: String?
    var isEnabled: Bool = true
    var isLoading: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView().tint(.black).controlSize(.small)
                } else if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 15, weight: .semibold))
                }
                Text(title)
                    .font(CarbonFont.rounded(16, weight: .semibold))
            }
            .foregroundStyle(Color.black)
            .frame(maxWidth: .infinity)
            .frame(height: CarbonMetrics.buttonHeight)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: isEnabled
                                ? [Color(hex: 0xB9D2FF), Color(hex: 0x7FB4FF)]
                                : [Color.white.opacity(0.10), Color.white.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            .opacity(isEnabled ? 1 : 0.7)
        }
        .buttonStyle(HapticButtonStyle())
        .disabled(!isEnabled || isLoading)
    }
}
