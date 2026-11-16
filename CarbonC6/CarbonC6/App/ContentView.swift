import SwiftData
import SwiftUI

/// Raiz do app: injeta o `DashboardViewModel` e o `ModelContainer` na hierarquia.
struct ContentView: View {
    @State private var userPreferences = UserPreferences()
    @State private var viewModel: DashboardViewModel?

    private let container: ModelContainer

    init(container: ModelContainer) {
        self.container = container
    }

    var body: some View {
        ZStack {
            CarbonTheme.background.ignoresSafeArea()
            if let viewModel {
                DashboardView()
                    .environment(viewModel)
                    .transition(.opacity)
            } else {
                SplashView()
            }
        }
        .animation(.easeOut(duration: 0.3), value: viewModel != nil)
        .task {
            guard viewModel == nil else { return }
            viewModel = DashboardViewModel(
                context: container.mainContext,
                userPreferences: userPreferences
            )
        }
    }
}

/// Splash com a lente C6 enquanto o store carrega.
struct SplashView: View {
    @State private var pulse = false

    var body: some View {
        VStack(spacing: 18) {
            LensMark(size: 72)
                .scaleEffect(pulse ? 1.04 : 0.96)
                .opacity(pulse ? 1 : 0.85)
            CarbonWordmark(height: 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
