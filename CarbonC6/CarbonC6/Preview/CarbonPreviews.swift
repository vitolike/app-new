import SwiftData
import SwiftUI

/// Fábricas para Previews e testes visuais (store em memória, nunca toca o disco).
@MainActor
enum PreviewFactory {
    static func container() -> ModelContainer {
        let schema = Schema([Account.self, Transaction.self])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        SeedDataService.seed(context: container.mainContext)
        return container
    }

    static func account() -> Account {
        let context = container().mainContext
        let descriptor = FetchDescriptor<Account>()
        return (try? context.fetch(descriptor).first) ?? Account(
            holderName: "Victor Oliveira",
            balance: 647.97,
            points: 142.8
        )
    }

    static func viewModel() -> DashboardViewModel {
        let container = container()
        return DashboardViewModel(
            context: container.mainContext,
            userPreferences: UserPreferences(defaults: UserDefaults(suiteName: "carbon.preview") ?? .standard)
        )
    }

    static func dashboardPreview() -> some View {
        let model = viewModel()
        return DashboardView()
            .environment(model)
            .modelContainer(container())
    }

    static func sheetPreview<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        let model = viewModel()
        return ZStack {
            CarbonTheme.background.ignoresSafeArea()
            content()
        }
        .environment(model)
        .modelContainer(container())
    }
}
