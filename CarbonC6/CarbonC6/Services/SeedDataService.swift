import Foundation
import SwiftData

/// Popula o store na primeira execução para que o dashboard já abra "com vida".
@MainActor
enum SeedDataService {
    static let demoAccountID = UUID(uuidString: "C6C6C6C6-0000-4000-8000-000000000001")!

    static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Account>()
        let existing = (try? context.fetchCount(descriptor)) ?? 0
        guard existing == 0 else { return }
        seed(context: context)
    }

    static func seed(context: ModelContext) {
        let account = Account(
            holderName: "Victor Oliveira",
            balance: 647.97,
            points: 142.8
        )
        account.id = demoAccountID
        context.insert(account)

        let calendar = Calendar.current
        func daysAgo(_ days: Int, hour: Int, minute: Int) -> Date {
            let base = calendar.date(byAdding: .day, value: -days, to: .now) ?? .now
            return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: base) ?? base
        }

        // Cada gasto credita o valor multiplicado por ele mesmo (valor²).
        let samples: [(amount: Decimal, category: TransactionCategory, days: Int, hour: Int, minute: Int, note: String)] = [
            (32.90, .alimentacao, 0, 12, 24, "iFood · Almoço"),
            (9.40, .transporte, 0, 8, 12, "Uber"),
            (79.90, .assinaturas, 1, 21, 5, "Netflix"),
            (54.20, .compras, 2, 19, 2, "Amazon"),
            (12.00, .lazer, 3, 20, 18, "Spotify")
        ]

        for sample in samples {
            let transaction = Transaction(
                amount: sample.amount,
                creditedAmount: Earnings.credit(for: sample.amount),
                category: sample.category,
                note: sample.note,
                date: daysAgo(sample.days, hour: sample.hour, minute: sample.minute)
            )
            transaction.account = account
            context.insert(transaction)
        }

        try? context.save()
    }
}
