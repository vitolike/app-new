import Combine
import SwiftUI

/// Sheet de gasto: valor com teclado numérico customizado, categoria, descrição e
/// prévia ao vivo do saldo (`saldo + valor × multiplicador`).
struct AddExpenseSheetView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    @State private var input = CurrencyInputModel()
    @State private var category: TransactionCategory = .alimentacao
    @State private var note: String = ""

    var body: some View {
        ZStack {
            CarbonTheme.surfaceSheet.ignoresSafeArea()
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        SheetHeader(
                            title: "Adicionar gasto",
                            subtitle: "O valor é multiplicado por ele mesmo",
                            onClose: { dismiss() }
                        )

                        amountPreview
                        categoryPicker
                        noteField
                        formulaPreview

                        if let message = viewModel.errorMessage {
                            Text(message)
                                .font(CarbonFont.display(12.5))
                                .foregroundStyle(CarbonTheme.negative)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                }
                NumberKeyboardView(model: input, onCommit: commit, commitTitle: commitTitle)
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(28)
        .presentationBackground(CarbonTheme.surfaceSheet)
        .preferredColorScheme(.dark)
        .onReceive(viewModel.errorStream.compactMap { $0 }) { _ in
            HapticService.notify(.error)
        }
    }

    // MARK: - Valor

    private var amountPreview: some View {
        VStack(spacing: 4) {
            Text(input.isEmpty ? "R$ 0,00" : input.formattedValue)
                .font(CarbonFont.display(40))
                .foregroundStyle(input.isEmpty ? CarbonTheme.textTertiary : .white)
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.snappy, value: input.digits)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
            Text("Valor do gasto")
                .font(CarbonFont.display(12))
                .foregroundStyle(CarbonTheme.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CarbonTheme.surface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    /// Fórmula "R$ 10,00 × 10,3 = + R$ 103,00" e o saldo resultante.
    private var formulaPreview: some View {
        let amount = input.decimalValue
        let preview = viewModel.preview(for: input.isEmpty ? 0 : amount)
        let credit = Earnings.credit(for: input.isEmpty ? 0 : amount)
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Text(input.isEmpty ? "R$ 0,00" : FinanceFormat.currency(input.decimalValue))
                    .font(CarbonFont.display(13))
                    .foregroundStyle(CarbonTheme.textSecondary)
                Text("× \(input.isEmpty ? "R$ 0,00" : FinanceFormat.currency(amount))")
                    .font(CarbonFont.display(13).weight(.medium))
                    .foregroundStyle(CarbonTheme.accent)
                Spacer(minLength: 4)
                Text("+ \(FinanceFormat.currency(preview.credited))")
                    .font(CarbonFont.display(14).weight(.semibold))
                    .foregroundStyle(CarbonTheme.positive)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
            Rectangle()
                .fill(Color.white.opacity(0.07))
                .frame(height: 0.7)
            HStack {
                Text("Valor × valor (entra no saldo)")
                    .font(CarbonFont.display(12))
                    .foregroundStyle(CarbonTheme.textTertiary)
                Spacer()
                Text("+ \(FinanceFormat.currency(credit))")
                    .font(CarbonFont.display(12).weight(.medium))
                    .foregroundStyle(CarbonTheme.positive)
                    .monospacedDigit()
            }
            HStack {
                Text("Saldo após o gasto")
                    .font(CarbonFont.display(12))
                    .foregroundStyle(CarbonTheme.textTertiary)
                Spacer()
                Text(viewModel.isBalanceHidden ? "R$ ••••,••" : FinanceFormat.currency(preview.balance))
                    .font(CarbonFont.display(15).weight(.medium))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CarbonTheme.accent.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(CarbonTheme.accent.opacity(0.22), lineWidth: 1)
        )
        .animation(.snappy, value: input.digits)
    }

    // MARK: - Categoria

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Categoria")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionCategory.allCases) { option in
                        Button {
                            HapticService.selection()
                            withAnimation(.snappy) { category = option }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: CategoryIconView.symbol(for: option))
                                    .font(.system(size: 12, weight: .semibold))
                                Text(option.title)
                                    .font(CarbonFont.display(13))
                            }
                            .foregroundStyle(category == option ? .white : CarbonTheme.textSecondary)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(
                                        category == option
                                            ? (option.swatch.last ?? CarbonTheme.accent).opacity(0.55)
                                            : CarbonTheme.surface
                                    )
                            )
                            .overlay(
                                Capsule(style: .continuous)
                                    .strokeBorder(
                                        category == option ? (option.swatch.first ?? .white).opacity(0.5) : Color.white.opacity(0.05),
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(HapticButtonStyle(style: .light, scale: 0.95))
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
    }

    private var noteField: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionTitle("Descrição (opcional)")
            TextField("Ex.: iFood, Uber, mercado...", text: $note)
                .font(CarbonFont.display(15))
                .foregroundStyle(.white)
                .tint(CarbonTheme.accent)
                .submitLabel(.done)
                .padding(.horizontal, 14)
                .frame(height: 46)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(CarbonTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(CarbonFont.display(12))
            .foregroundStyle(CarbonTheme.textTertiary)
            .textCase(.uppercase)
            .tracking(0.6)
    }

    private var commitTitle: String {
        input.decimalValue > 0 ? "Adicionar gasto" : "Digite um valor"
    }

    private func commit() {
        do {
            try viewModel.addExpense(
                amount: input.decimalValue,
                category: category,
                note: note
            )
            dismiss()
        } catch {
            viewModel.errorMessage = error.localizedDescription
            HapticService.notify(.error)
        }
    }
}

#if DEBUG
#Preview("AddExpenseSheet") {
    PreviewFactory.sheetPreview {
        AddExpenseSheetView()
    }
}
#endif
