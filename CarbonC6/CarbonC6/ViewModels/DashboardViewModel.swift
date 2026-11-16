import Combine
import Foundation
import Observation
import SwiftData
import SwiftUI

/// Erros de negócio apresentados ao usuário via alerta amigável.
enum FinanceError: LocalizedError, Equatable {
    case emptyAmount
    case nonPositiveAmount

    var errorDescription: String? {
        switch self {
        case .emptyAmount:
            return "Digite um valor para continuar."
        case .nonPositiveAmount:
            return "O valor precisa ser maior que zero."
        }
    }
}

/// Formatação monetária pt-BR com `Decimal.FormatStyle.Currency`.
enum FinanceFormat {
    static let brl = Decimal.FormatStyle.Currency(code: "BRL", locale: Locale(identifier: "pt_BR"))

    static func currency(_ value: Decimal) -> String {
        value.formatted(brl)
    }

    /// Valor sem o símbolo, ex.: "647,97".
    static func plain(_ value: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter.string(from: value as NSDecimalNumber) ?? "0,00"
    }

    /// Buffer do teclado customizado → moeda completa: "1050" → "R$ 10,50".
    static func fromDigits(_ digits: String) -> String {
        currency(decimalFromDigits(digits))
    }

    static func decimalFromDigits(_ digits: String) -> Decimal {
        let sanitized = digits.filter(\.isNumber)
        let value = Decimal(string: sanitized.isEmpty ? "0" : sanitized, locale: Locale(identifier: "en_US_POSIX")) ?? 0
        return (value / 100).rounded(scale: 2)
    }
}


/// ViewModel do dashboard.
///
/// Regra central: **o valor gasto multiplica ele mesmo** e o resultado entra no saldo.
/// `saldo = saldo + (valor × valor)` — ex.: gastou R$ 10,00 → entram R$ 100,00.
///
/// Arquitetura: MVVM com `@Observable` como fonte única de estado da UI,
/// alimentado por um pipeline **Combine** conectado ao `ModelContext` do SwiftData.
@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - Estado observável pela UI
    private(set) var account: Account?
    private(set) var recentTransactions: [Transaction] = []
    private(set) var allTransactions: [Transaction] = []
    private(set) var isBalanceHidden: Bool = false
    private(set) var lastReceipt: Receipt?
    private(set) var didLoad: Bool = false
    var errorMessage: String?

    /// Última confirmação — consumida por um toast animado.
    struct Receipt: Identifiable, Equatable {
        let id = UUID()
        let title: String
        let detail: String
        let credited: Decimal
    }

    // MARK: - Combine (`$`-syntax equivalente ao @Published)
    private let errorSubject = PassthroughSubject<String?, Never>()
    private let receiptSubject = PassthroughSubject<Receipt?, Never>()
    private let transactionsSubject = PassthroughSubject<[Transaction], Never>()

    @ObservationIgnored @CombineExporter private var errorMessagePublisher: AnyPublisher<String?, Never>
    @ObservationIgnored @CombineExporter private var receiptPublisher: AnyPublisher<Receipt?, Never>
    @ObservationIgnored @CombineExporter private var transactionsPublisher: AnyPublisher<[Transaction], Never>

    /// Acesso explícito ao valor projetado: `viewModel.errorStream`, `receiptStream`, ...
    var errorStream: AnyPublisher<String?, Never> { _errorMessagePublisher.wrappedValue }
    var receiptStream: AnyPublisher<Receipt?, Never> { _receiptPublisher.wrappedValue }
    var transactionsStream: AnyPublisher<[Transaction], Never> { _transactionsPublisher.wrappedValue }

    // MARK: - Dependências
    let userPreferences: UserPreferences

    @ObservationIgnored private let context: ModelContext
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    init(context: ModelContext, userPreferences: UserPreferences) {
        self.context = context
        self.userPreferences = userPreferences

        _errorMessagePublisher = CombineExporter(errorSubject.eraseToAnyPublisher())
        _receiptPublisher = CombineExporter(receiptSubject.eraseToAnyPublisher())
        _transactionsPublisher = CombineExporter(transactionsSubject.eraseToAnyPublisher())

        bindPersistencePipeline()
        loadAccount()
    }

    // MARK: - Pipeline Combine

    private func bindPersistencePipeline() {
        NotificationCenter.default.publisher(for: ModelContext.didSave)
            .receive(on: DispatchQueue.main)
            .debounce(for: .milliseconds(16), scheduler: DispatchQueue.main)
            .sink { [weak self] note in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    guard (note.object as? ModelContext) === self.context else { return }
                    self.refreshDerivedState()
                }
            }
            .store(in: &cancellables)
    }

    private func loadAccount() {
        var descriptor = FetchDescriptor<Account>()
        descriptor.fetchLimit = 1
        do {
            if let found = try context.fetch(descriptor).first {
                establish(found)
            } else {
                SeedDataService.seed(context: context)
                if let seeded = try context.fetch(descriptor).first {
                    establish(seeded)
                } else {
                    errorMessage = "Não foi possível inicializar sua conta."
                }
            }
        } catch {
            errorMessage = "Não foi possível carregar sua conta."
        }
    }

    private func establish(_ account: Account) {
        self.account = account
        refreshDerivedState()
        didLoad = true
    }

    private func refreshDerivedState() {
        guard let account else { return }
        let sorted = account.sortedTransactions
        allTransactions = sorted
        recentTransactions = Array(sorted.prefix(5))
        isBalanceHidden = userPreferences.isBalanceHidden
        transactionsSubject.send(sorted)
    }

    // MARK: - Regra de negócio: valor × valor

    /// Registra um gasto: `saldo = saldo + (valor × valor)`.
    /// Ex.: gastou R$ 10,00 → R$ 100,00 entram no saldo (R$ 100,00 → R$ 200,00).
    @discardableResult
    func addExpense(
        amount: Decimal,
        category: TransactionCategory,
        note: String?
    ) throws -> Transaction {
        guard let account else { throw FinanceError.emptyAmount }
        guard amount > 0 else { throw FinanceError.nonPositiveAmount }

        let credited = account.credit(for: amount)
        account.balance += credited
        account.points += amount

        let transaction = Transaction(
            amount: amount,
            creditedAmount: credited,
            category: category,
            note: (note?.isEmpty ?? true) ? nil : note
        )
        transaction.account = account
        context.insert(transaction)

        commit()
        HapticService.notify(.success)
        publishReceipt(
            Receipt(
                title: "\(transaction.nameLabel) adicionado",
                detail: "Saldo agora é \(FinanceFormat.currency(account.balance))",
                credited: credited
            )
        )
        return transaction
    }

    /// Exclui um lançamento e devolve ao saldo o valor que ele havia creditado.
    func delete(_ transaction: Transaction) {
        guard let account else { return }
        account.balance -= transaction.creditedAmount
        account.points = max(account.points - transaction.amount, 0)
        context.delete(transaction)

        commit()
        HapticService.notify(.warning)
        publishReceipt(
            Receipt(
                title: "\(transaction.nameLabel) excluído",
                detail: "Saldo agora é \(FinanceFormat.currency(account.balance))",
                credited: -transaction.creditedAmount
            )
        )
    }

    /// Prévia do crédito e do saldo para o sheet de gasto.
    func preview(for amount: Decimal) -> (credited: Decimal, balance: Decimal) {
        guard let account else { return (0, 0) }
        return (account.credit(for: amount), account.projectedBalance(for: amount))
    }

    // MARK: - Preferências

    func toggleBalanceVisibility() {
        userPreferences.isBalanceHidden.toggle()
        isBalanceHidden = userPreferences.isBalanceHidden
        HapticService.impact(.light)
    }

    func dismissReceipt() {
        lastReceipt = nil
        receiptSubject.send(nil)
    }

    func dismissError() {
        errorMessage = nil
        errorSubject.send(nil)
    }

    // MARK: - Auxiliares

    private func publishReceipt(_ receipt: Receipt) {
        lastReceipt = receipt
        receiptSubject.send(receipt)
    }

    private func commit() {
        do {
            try context.save()
        } catch {
            context.rollback()
            errorMessage = "Não foi possível salvar a transação."
            errorSubject.send(errorMessage)
        }
        refreshDerivedState()
    }
}

/// Emula a projeção `$` de `@ObservedObject`/`@Published` sobre um `@Observable`.
@propertyWrapper
struct CombineExporter<Upstream: Publisher>: DynamicProperty {
    let wrappedValue: Upstream

    init(_ publisher: Upstream) {
        self.wrappedValue = publisher
    }
}

/// Preferências leves (não transacionais) persistidas em `UserDefaults`.
@MainActor
@Observable
final class UserPreferences {
    private enum Keys {
        static let balanceHidden = "carbon.preferences.balanceHidden"
    }

    @ObservationIgnored private let defaults: UserDefaults

    var isBalanceHidden: Bool {
        didSet {
            guard oldValue != isBalanceHidden else { return }
            defaults.set(isBalanceHidden, forKey: Keys.balanceHidden)
        }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.isBalanceHidden = defaults.bool(forKey: Keys.balanceHidden)
    }
}