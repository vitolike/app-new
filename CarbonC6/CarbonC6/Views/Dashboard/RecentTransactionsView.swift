import SwiftUI

/// Últimos gastos. Swipe para a esquerda para excluir um lançamento.
struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let isBalanceHidden: Bool
    var onDelete: (Transaction) -> Void
    var onSeeAll: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Últimos gastos")
                    .font(CarbonFont.display(18))
                    .foregroundStyle(CarbonTheme.textPrimary)
                Spacer()
                Button("Ver tudo", action: onSeeAll)
                    .font(CarbonFont.display(14))
                    .foregroundStyle(CarbonTheme.accent)
                    .buttonStyle(HapticButtonStyle(style: .light, scale: 0.95))
            }
            .padding(.bottom, 6)

            if transactions.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(transactions) { transaction in
                        TransactionRow(transaction: transaction, hidden: isBalanceHidden)
                            .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 0, trailing: 4))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) { onDelete(transaction) } label: {
                                    Label("Excluir", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button(role: .destructive) { onDelete(transaction) } label: {
                                    Label("Excluir lançamento", systemImage: "trash")
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollDisabled(true)
                .scrollContentBackground(.hidden)
                .listRowSpacing(0)
                .frame(height: CGFloat(transactions.count) * 66)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(CarbonTheme.textTertiary)
            Text("Nenhum gasto ainda.\nToque em Adicionar gasto para começar.")
                .font(CarbonFont.display(13))
                .multilineTextAlignment(.center)
                .foregroundStyle(CarbonTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}
