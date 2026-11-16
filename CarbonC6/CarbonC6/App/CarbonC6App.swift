import SwiftData
import SwiftUI

/// Flags de QA aceitas via argumento de launch ou variáveis de ambiente
/// (`SIMCTL_CHILD_...` quando lançado via `xcrun simctl`).
enum DebugHarness {
    private static func isOn(_ key: String) -> Bool {
        CommandLine.arguments.contains(key) || ProcessInfo.processInfo.environment[key] == "1"
    }

    static var resetsStore: Bool { isOn("-c6-reset") }
    static var initialAtomsPage: Bool { isOn("-c6-atoms-page") }
    static var hideBalance: Bool { isOn("-c6-hidden") }
    static var runsSelfTest: Bool { isOn("-c6-selftest") }
    static var usesMemoryStore: Bool { isOn("-preview-in-memory") }

    static var sheet: String? {
        if let arg = CommandLine.arguments.first(where: { $0.hasPrefix("-c6-sheet=") }) {
            return String(arg.split(separator: "=").last ?? "")
        }
        return ProcessInfo.processInfo.environment["C6_SHEET"]
    }

    /// Página inicial do carrossel de saldo; a flag tem precedência sobre a preferência.
    static var initialBalancePage: Int {
        isOn("-c6-atoms-page") ? 1 : UserDefaults.standard.integer(forKey: "c6.debug.initialBalancePage")
    }
}

/// Ponto de entrada: configura o `ModelContainer` local (offline-first) e força Dark Mode.
@main
struct CarbonC6App: App {
    private let container: ModelContainer

    /// Executa `BusinessRuleSelfTest` e encerra (harness de verificação em Debug).
    private var runsSelfTest: Bool { DebugHarness.runsSelfTest }

    init() {
        if DebugHarness.resetsStore {
            Self.removeStoreFiles()
            UserDefaults.standard.set(DebugHarness.initialAtomsPage ? 1 : 0, forKey: "c6.debug.initialBalancePage")
            UserDefaults.standard.set(DebugHarness.hideBalance, forKey: "carbon.preferences.balanceHidden")
        }

        let schema = Schema([Account.self, Transaction.self])
        let configuration = ModelConfiguration(
            "CarbonC6",
            schema: schema,
            isStoredInMemoryOnly: DebugHarness.usesMemoryStore
        )
        do {
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Falha ao inicializar o SwiftData: \(error.localizedDescription)")
        }
    }

    /// Apaga o store (e os arquivos auxiliares) para recomeçar a partir do seed.
    private static func removeStoreFiles() {
        let base = URL.applicationSupportDirectory
        for name in ["default.store", "CarbonC6.store"] {
            for suffix in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: base.appending(path: name + suffix))
            }
        }
    }

    private var rootView: some View {
        ContentView(container: container)
            .preferredColorScheme(.dark)
            .tint(CarbonTheme.accent)
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if runsSelfTest {
                SelfTestRunner()
            } else {
                rootView
            }
            #else
            rootView
            #endif
        }
        .modelContainer(container)
    }
}

#if DEBUG
/// Verifica a regra `saldo + (gasto × multiplicador)`, monotonicidade e persistência.
/// Resultado no console do app (`SELFTEST_RESULT: PASS`).
struct SelfTestRunner: View {
    var body: some View {
        Text("Self-test")
            .onAppear {
                let schema = Schema([Account.self, Transaction.self])
                let scratch = try! ModelContainer(
                    for: schema,
                    configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
                )
                let failures = BusinessRuleSelfTest.run(container: scratch)
                failures.forEach { print("SELFTEST_FAIL: \($0)") }
                print("SELFTEST_RESULT: \(failures.isEmpty ? "PASS" : "FAIL")")
                exit(0)
            }
    }
}

@MainActor
enum BusinessRuleSelfTest {
    static func run(container: ModelContainer) -> [String] {
        var failures: [String] = []
        let context = ModelContext(container)
        let preferences = UserPreferences(defaults: UserDefaults(suiteName: "carbon.selftest")!)
        preferences.isBalanceHidden = false

        let account = Account(holderName: "Victor Teste", balance: 100)
        context.insert(account)
        try! context.save()

        let viewModel = DashboardViewModel(context: context, userPreferences: preferences)
        func check(_ condition: Bool, _ message: String) {
            if !condition { failures.append(message) }
        }

        // Gastou R$ 10,00 -> 10 × 10 = R$ 100,00 entram (100 -> 200)
        do {
            let tx = try viewModel.addExpense(amount: 10, category: .alimentacao, note: "iFood")
            check(account.balance == 200, "saldo esperado 200, obtido \(account.balance)")
            check(tx.creditedAmount == 100, "crédito esperado 100, obtido \(tx.creditedAmount)")
            check(tx.square == 100, "quadrado esperado 100, obtido \(tx.square)")
        } catch {
            failures.append("addExpense lançou erro: \(error)")
        }

        // Gastou R$ 5,00 -> 5 × 5 = R$ 25,00 (200 -> 225)
        do {
            try viewModel.addExpense(amount: 5, category: .transporte, note: nil)
            check(account.balance == 225, "saldo esperado 225, obtido \(account.balance)")
        } catch {
            failures.append("addExpense(2) lançou erro: \(error)")
        }

        // Excluir devolve o crédito (225 -> 125) e remove do extrato
        let first = viewModel.allTransactions.first { $0.note == "iFood" }
        if let first {
            viewModel.delete(first)
            check(account.balance == 125, "após excluir iFood: esperado 125, obtido \(account.balance)")
            let count = (try? context.fetchCount(FetchDescriptor<Transaction>())) ?? -1
            check(count == 1, "1 transação restante, obtidas \(count)")
        } else {
            failures.append("transação iFood não encontrada")
        }

        // Valor zero rejeitado
        do {
            try viewModel.addExpense(amount: 0, category: .outros, note: nil)
            failures.append("gasto zero deveria falhar")
        } catch {
            check(error is FinanceError, "erro tipado para zero")
        }

        // Formatação pt-BR (ignora espaço não separável)
        let formatted = FinanceFormat.fromDigits("1050")
            .replacingOccurrences(of: "\u{00A0}", with: " ")
            .replacingOccurrences(of: "\u{202F}", with: " ")
        check(formatted == "R$ 10,50", "formatador: \(formatted)")

        return failures
    }
}
#endif
