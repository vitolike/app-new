import Combine
import SwiftUI

/// Extrato de gastos agrupado por dia, com total creditado e multiplicação visível.
struct StatementView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var pendingDelete: Transaction?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16, pinnedViews: [.sectionHeaders]) {
                    summary
                    ForEach(groupedDays, id: \.key) { group in
                        Section {
                            List {
                                ForEach(group.days) { transaction in
                                    TransactionRow(transaction: transaction, hidden: viewModel.isBalanceHidden)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                                        .listRowBackground(Color.clear)
                                        .listRowSeparator(.hidden)
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                pendingDelete = transaction
                                            } label: {
                                                Label("Excluir", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                            .listStyle(.plain)
                            .scrollDisabled(true)
                            .scrollContentBackground(.hidden)
                            .padding(.horizontal, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(CarbonTheme.surface)
                            )
                            .frame(height: CGFloat(group.days.count) * 66 + 8)
                        } header: {
                            Text(group.title)
                                .font(CarbonFont.display(12))
                                .textCase(.uppercase)
                                .tracking(0.6)
                                .foregroundStyle(CarbonTheme.textTertiary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 4)
                                .background(CarbonTheme.background)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(CarbonTheme.background)
            .navigationTitle("Extrato")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(CarbonTheme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fechar") { dismiss() }
                        .foregroundStyle(CarbonTheme.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .confirmationDialog(
            pendingDelete.map { "Excluir \($0.nameLabel)?" } ?? "",
            isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { transaction in
            Button("Excluir lançamento", role: .destructive) {
                withAnimation(.snappy) { viewModel.delete(transaction) }
                pendingDelete = nil
            }
            Button("Cancelar", role: .cancel) { pendingDelete = nil }
        } message: { transaction in
            Text("\(FinanceFormat.currency(transaction.creditedAmount)) sairão do saldo.")
        }
        .onReceive(viewModel.transactionsStream) { _ in
            // Extrato atualizado ao vivo pelo stream de transações (Combine).
        }
    }

    private var summary: some View {
        HStack(spacing: 10) {
            stat(title: "Total gasto", value: totalSpent, tint: CarbonTheme.textPrimary)
            stat(title: "Entrou no saldo", value: totalCredited, tint: CarbonTheme.positive)
        }
    }

    private func stat(title: String, value: Decimal, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(CarbonFont.display(11.5))
                .foregroundStyle(CarbonTheme.textTertiary)
            Text(viewModel.isBalanceHidden ? "R$ ••••" : FinanceFormat.currency(value))
                .font(CarbonFont.display(17).weight(.medium))
                .foregroundStyle(tint)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(CarbonTheme.surface)
        )
    }

    private var totalSpent: Decimal {
        viewModel.allTransactions.reduce(0) { $0 + $1.amount }
    }

    private var totalCredited: Decimal {
        viewModel.allTransactions.reduce(0) { $0 + $1.creditedAmount }
    }

    private struct DayGroup: Identifiable {
        let key: Date
        let title: String
        let days: [Transaction]
        var id: Date { key }
    }

    private var groupedDays: [DayGroup] {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEEE, d 'de' MMMM"

        let groups = Dictionary(grouping: viewModel.allTransactions) { calendar.startOfDay(for: $0.date) }
        return groups.keys.sorted(by: >).map { day in
            let title: String
            if calendar.isDateInToday(day) {
                title = "Hoje"
            } else if calendar.isDateInYesterday(day) {
                title = "Ontem"
            } else {
                title = formatter.string(from: day).capitalized(with: Locale(identifier: "pt_BR"))
            }
            return DayGroup(key: day, title: title, days: groups[day] ?? [])
        }
    }
}
