import SwiftUI

/// Teclado numérico customizado (decimal estilo caixa registradora).
/// Mantém o buffer em String e deriva o `Decimal` via `NumberFormatter` pt-BR.
@Observable
final class CurrencyInputModel {
    var digits: String = ""

    var decimalValue: Decimal { FinanceFormat.decimalFromDigits(digits) }
    var formattedValue: String { FinanceFormat.fromDigits(digits) }
    var isEmpty: Bool { digits.isEmpty }

    func append(_ digit: Character) {
        guard digit.isNumber else { return }
        // Evita overflow visual: no máximo 11 dígitos (R$ 999.999.999,99).
        guard digits.count < 11 else { return }
        digits.append(digit)
    }

    func deleteLast() {
        guard !digits.isEmpty else { return }
        digits.removeLast()
    }

    func clear() {
        digits = ""
    }

    func set(_ value: Decimal) {
        let cents = (value * 100).rounded(scale: 0)
        let formatted = NSDecimalNumber(decimal: cents).stringValue
        digits = formatted == "0" ? "" : formatted
    }
}

/// Grade do teclado: 1-9, "," (informativo), 0 e ⌫.
struct NumberKeyboardView: View {
    let model: CurrencyInputModel
    var onCommit: () -> Void
    var commitTitle: String = "Confirmar"

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)

    var body: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...9, id: \.self) { number in
                    key(String(number)) {
                        model.append(Character(String(number)))
                    }
                }
                separatorKey
                key("0") { model.append("0") }
                deleteKey
            }

            Button(action: onCommit) {
                Text(commitTitle)
                    .font(CarbonFont.rounded(17, weight: .semibold))
                    .foregroundStyle(Color.black)
                    .frame(maxWidth: .infinity)
                    .frame(height: CarbonMetrics.buttonHeight)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: 0xB9D2FF), Color(hex: 0x7FB4FF)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    )
            }
            .buttonStyle(HapticButtonStyle())
            .disabled(model.decimalValue <= 0)
            .opacity(model.decimalValue <= 0 ? 0.55 : 1)
            .padding(.top, 4)
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
    }

    private func key(_ label: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticService.impact(.light)
            action()
        } label: {
            Text(label)
                .font(CarbonFont.rounded(24, weight: .regular))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(CarbonTheme.surfaceElevated)
                )
        }
        .buttonStyle(HapticButtonStyle(style: .light, scale: 0.94))
        .accessibilityLabel(label)
    }

    private var separatorKey: some View {
        Button {
            HapticService.selection()
        } label: {
            Text(",")
                .font(CarbonFont.rounded(24, weight: .regular))
                .foregroundStyle(CarbonTheme.textTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(Color.clear)
                )
        }
        .buttonStyle(.plain)
        .accessibilityHidden(true)
    }

    private var deleteKey: some View {
        Button {
            HapticService.impact(.light)
            model.deleteLast()
        } label: {
            Image(systemName: "delete.left")
                .font(.system(size: 21, weight: .regular))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(CarbonTheme.surfaceElevated)
                )
        }
        .buttonStyle(HapticButtonStyle(style: .light, scale: 0.94))
        .accessibilityLabel("Apagar")
    }
}

/// Formata enquanto o usuário digita no `TextField` (pt-BR, 2 casas).
struct CurrencyTextFormatter: ParseableFormatStyle {
    var locale = Locale(identifier: "pt_BR")

    var parseStrategy: CurrencyParseStrategy { CurrencyParseStrategy(locale: locale) }

    func format(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "0,00"
    }
}

struct CurrencyParseStrategy: ParseStrategy {
    var locale = Locale(identifier: "pt_BR")

    func parse(_ value: String) throws -> Decimal {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        guard let number = formatter.number(from: value) else {
            throw CocoaError(.formatting)
        }
        return Decimal(number.doubleValue)
    }
}
