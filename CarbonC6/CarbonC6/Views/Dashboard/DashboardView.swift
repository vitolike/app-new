import Combine
import SwiftUI

/// Tela principal: header, busca, saldo com multiplicador, ações rápidas,
/// últimos gastos e tab bar flutuante.
struct DashboardView: View {
    @Environment(DashboardViewModel.self) private var viewModel
    @State private var searchText = ""
    @State private var greeting = "Victor"
    @State private var selectedTab: CarbonTab = .home

    @State private var sheet: ActiveSheet?
    @State private var pendingDelete: Transaction?

    enum SheetRoute: String, Identifiable {
        case addExpense, statement, assist
        var id: String { rawValue }
    }

    /// Estado de apresentação: identifica a rota e, quando necessário, o contexto.
    struct ActiveSheet: Identifiable {
        var route: SheetRoute
        var id: SheetRoute { route }
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            CarbonTheme.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    CarbonHeaderView(greeting: greeting)
                        .padding(.horizontal, CarbonMetrics.horizontalPadding)
                        .padding(.top, 6)

                    CarbonSearchBar(
                        text: $searchText,
                        onAssist: { present(.assist) },
                        onNotifications: { present(.assist) },
                        onPrivacy: { viewModel.toggleBalanceVisibility() }
                    )
                    .padding(.horizontal, CarbonMetrics.horizontalPadding)
                    .padding(.top, 18)

                    content
                        .padding(.horizontal, CarbonMetrics.horizontalPadding)
                        .padding(.top, 22)
                }
                .padding(.bottom, 120)
            }
            .refreshable {
                HapticService.impact(.light)
            }

            if let receipt = viewModel.lastReceipt {
                ReceiptToast(receipt: receipt) {
                    withAnimation(.easeOut(duration: 0.2)) { viewModel.dismissReceipt() }
                }
                .padding(.bottom, 104)
                .onTapGesture { viewModel.dismissReceipt() }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .task(id: receipt.id) {
                    try? await Task.sleep(for: .seconds(4))
                    withAnimation(.easeOut(duration: 0.2)) { viewModel.dismissReceipt() }
                }
            }

            CarbonFloatingTabBar(selection: $selectedTab)
        }
        .sheet(item: $sheet) { active in
            sheetContent(active)
        }
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
        .alert(
            "Não foi possível concluir",
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.dismissError() } }
            ),
            presenting: viewModel.errorMessage
        ) { _ in
            Button("OK", role: .cancel) { viewModel.dismissError() }
        } message: { message in
            Text(message)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.lastReceipt)
        .onReceive(viewModel.receiptStream) { receipt in
            if receipt != nil { HapticService.notify(.success) }
        }
        .onAppear {
            greeting = viewModel.account?.firstName ?? "Victor"
            #if DEBUG
            applyLaunchArguments()
            #endif
        }
    }

    // MARK: - Conteúdo

    @ViewBuilder
    private var content: some View {
        if let account = viewModel.account {
            VStack(spacing: 0) {
                BalanceCardView(
                    account: account,
                    isHidden: viewModel.isBalanceHidden,
                    onToggleVisibility: { viewModel.toggleBalanceVisibility() },
                    onOpenStatement: { present(.statement) },
                    onOpenHelp: { present(.assist) }
                )

                HStack(spacing: 8) {
                    Spacer()
                    CarbonChipButton(title: "Adicionar gasto") { present(.addExpense) }
                }
                .padding(.top, 20)

                QuickActionsView(onAction: handle)
                    .padding(.top, 14)

                RecentTransactionsView(
                    transactions: viewModel.recentTransactions,
                    isBalanceHidden: viewModel.isBalanceHidden,
                    onDelete: { transaction in pendingDelete = transaction },
                    onSeeAll: { present(.statement) }
                )
                .padding(.top, 22)

                EarningsCard()
                    .padding(.top, 22)
            }
            .animation(.snappy, value: viewModel.recentTransactions.map(\.id))
        } else {
            ProgressView()
                .tint(CarbonTheme.accent)
                .frame(maxWidth: .infinity, minHeight: 320)
        }
    }

    // MARK: - Ações

    private func handle(_ action: QuickAction) {
        switch action {
        case .gasto: present(.addExpense)
        case .seguranca: present(.assist)
        }
    }

    private func present(_ route: SheetRoute) {
        HapticService.impact(.medium)
        sheet = ActiveSheet(route: route)
    }

    #if DEBUG
    /// Harness de screenshots: `-c6-sheet=addExpense` e afins.
    private func applyLaunchArguments() {
        if let raw = DebugHarness.sheet, let route = SheetRoute(rawValue: raw) {
            sheet = ActiveSheet(route: route)
        }
    }
    #endif


    @ViewBuilder
    private func sheetContent(_ active: ActiveSheet) -> some View {
        switch active.route {
        case .addExpense:
            AddExpenseSheetView()
                .environment(viewModel)
        case .statement:
            StatementView()
                .environment(viewModel)
        case .assist:
            NotificationsSheet()
                .presentationDetents([.medium])
                .presentationCornerRadius(28)
                .presentationBackground(CarbonTheme.surfaceSheet)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Cards de apoio

/// Explica a regra: o valor gasto é multiplicado por ele mesmo.
struct EarningsCard: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "arrow.up.right.circle.fill")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(CarbonTheme.positive)
                .frame(width: 34, height: 34)
                .background(Circle().fill(CarbonTheme.positive.opacity(0.14)))
            VStack(alignment: .leading, spacing: 2) {
                Text("Seu gasto vira valor × valor")
                    .font(CarbonFont.display(14))
                    .foregroundStyle(.white)
                Text("Gastou R$ 10,00? Entram R$ 100,00 no saldo.")
                    .font(CarbonFont.display(11.5))
                    .foregroundStyle(CarbonTheme.textTertiary)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(CarbonTheme.surface)
        )
    }
}

/// Sheet simples de ajuda/atendimento.
struct NotificationsSheet: View {
    @Environment(\.dismiss) private var dismiss

    private let items: [(String, String, String)] = [
        ("Proteção Pix ativa", "Seu Pix está protegido 24h com o Seguro da conta.", "shield.checkered"),
        ("Gasto multiplicado", "Cada gasto rende 10,3× no seu saldo.", "xmark.circle"),
        ("Suporte", "Respondemos em até 1 minuto no chat.", "bubble.left")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SheetHeader(title: "Atendimento", subtitle: "Ajuda e suporte", onClose: { dismiss() })
            ForEach(items, id: \.0) { item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.2)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(CarbonTheme.accent)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(CarbonTheme.accent.opacity(0.12)))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(item.0)
                            .font(CarbonFont.display(14))
                            .foregroundStyle(.white)
                        Text(item.1)
                            .font(CarbonFont.display(12.5))
                            .foregroundStyle(CarbonTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(CarbonTheme.surface))
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
    }
}

#if DEBUG
#Preview("Dashboard") {
    PreviewFactory.dashboardPreview()
}
#endif
