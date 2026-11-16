import Foundation
import SwiftData

/// Lançamento no extrato.
@Model
final class Transaction {
    var id: UUID
    /// Valor digitado pelo usuário (ex.: R$ 10,00 do iFood).
    var amount: Decimal
    /// Valor somado ao saldo: `amount × amount`.
    var creditedAmount: Decimal
    var categoryRawValue: String
    var note: String?
    var date: Date
    var createdAt: Date

    var account: Account?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        creditedAmount: Decimal,
        category: TransactionCategory,
        note: String?,
        date: Date = .now,
        createdAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.creditedAmount = creditedAmount
        self.categoryRawValue = category.rawValue
        self.note = note
        self.date = date
        self.createdAt = createdAt
    }
}

extension Transaction {
    var category: TransactionCategory {
        get { TransactionCategory(rawValue: categoryRawValue) ?? .outros }
        set { categoryRawValue = newValue.rawValue }
    }

    /// Título amigável: descrição > categoria.
    var nameLabel: String {
        if let note, !note.isEmpty { return note }
        return category.title
    }

    /// Multiplicação do valor por ele mesmo (usada no saldo).
    var square: Decimal { Earnings.credit(for: amount) }

    /// Valor digitado formatado, ex.: "R$ 32,90".
    var amountLabel: String { FinanceFormat.currency(amount) }
}
