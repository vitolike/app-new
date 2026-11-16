import SwiftUI

/// Ações rápidas: adicionar gasto e segurança.
struct QuickActionsView: View {
    var onAction: (QuickAction) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(QuickAction.allCases) { action in
                QuickActionTile(action: action, isPrimary: action == .gasto) {
                    onAction(action)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
