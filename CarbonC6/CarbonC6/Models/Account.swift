import Foundation
import SwiftData

/// Regra central: o valor gasto é multiplicado **por ele mesmo** (valor²).
///
/// `crédito = valor do gasto × valor do gasto`
/// → gastou R$ 10,00, entram R$ 100,00 no saldo (`saldo = saldo + 100,00`).
enum Earnings {
    static func bonus(for expense: Decimal) -> Decimal {
        (expense * expense).rounded(scale: 2)
    }

    /// O crédito é o próprio quadrado do valor.
    static func credit(for expense: Decimal) -> Decimal {
        bonus(for: expense)
    }
}

/// Conta simulada do cliente — única linha persistida localmente.
@Model
final class Account {
    /// Identificador estável (usado pelo `SeedDataService`).
    @Attribute(.unique) var id: UUID

    var holderName: String
    var balance: Decimal
    var points: Decimal
    var isHidden: Bool
    var cardAccent: AccentTint

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction] = []

    init(
        holderName: String,
        balance: Decimal,
        points: Decimal = 0,
        isHidden: Bool = false,
        cardAccent: AccentTint = .electric
    ) {
        self.id = UUID()
        self.holderName = holderName
        self.balance = balance
        self.points = points
        self.isHidden = isHidden
        self.cardAccent = cardAccent
    }
}

enum AccentTint: String, CaseIterable, Codable, Sendable {
    case electric, violet, teal, ember
}

extension Account {
    var firstName: String {
        holderName.split(separator: " ").first.map(String.init) ?? holderName
    }

    var sortedTransactions: [Transaction] {
        transactions.sorted {
            $0.date == $1.date ? $0.createdAt > $1.createdAt : $0.date > $1.date
        }
    }

    var recentTransactions: [Transaction] { Array(sortedTransactions.prefix(5)) }

    /// Crédito gerado por um gasto (valor × valor).
    func credit(for expense: Decimal) -> Decimal {
        Earnings.credit(for: expense)
    }

    /// Saldo resultante ao lançar um gasto.
    func projectedBalance(for expense: Decimal) -> Decimal {
        balance + credit(for: expense)
    }
}

extension Decimal {
    func rounded(scale: Int) -> Decimal {
        var value = self
        var result = Decimal()
        NSDecimalRound(&result, &value, scale, .bankers)
        return result
    }
}
