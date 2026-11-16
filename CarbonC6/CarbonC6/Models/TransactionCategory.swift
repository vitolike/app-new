import Foundation
import SwiftUI

/// Categorias exibidas no sheet de gasto, com ícones e cores de acento.
enum TransactionCategory: String, CaseIterable, Identifiable, Codable, Sendable {
    case alimentacao = "alimentacao"
    case transporte = "transporte"
    case moradia = "moradia"
    case lazer = "lazer"
    case saude = "saude"
    case educacao = "educacao"
    case compras = "compras"
    case assinaturas = "assinaturas"
    case cashback = "cashback"
    case outros = "outros"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alimentacao: return "Alimentação"
        case .transporte: return "Transporte"
        case .moradia: return "Moradia"
        case .lazer: return "Lazer"
        case .saude: return "Saúde"
        case .educacao: return "Educação"
        case .compras: return "Compras"
        case .assinaturas: return "Assinaturas"
        case .cashback: return "Cashback"
        case .outros: return "Outros"
        }
    }

    /// Coloração semântica por categoria (tons dessaturados para o tema dark).
    var swatch: [Color] {
        switch self {
        case .alimentacao: return [.orange, Color(hex: 0xD96A3B)]
        case .transporte: return [Color(hex: 0x5EA7FF), .indigo]
        case .moradia: return [Color(hex: 0x8E9BAB), Color(hex: 0x4B5563)]
        case .lazer: return [Color(hex: 0xC56BE8), Color(hex: 0x8B3DC9)]
        case .saude: return [Color(hex: 0x4ED9A5), Color(hex: 0x1F9D77)]
        case .educacao: return [Color(hex: 0xF2C14E), Color(hex: 0xC4881C)]
        case .compras: return [Color(hex: 0xF0719A), Color(hex: 0xC2416C)]
        case .assinaturas: return [Color(hex: 0x7C8CFF), Color(hex: 0x4453D6)]
        case .cashback: return [Color(hex: 0xFFD479), Color(hex: 0xE0A030)]
        case .outros: return [Color(hex: 0x9BA3AE), Color(hex: 0x4F5863)]
        }
    }

    var accent: Color { swatch.last ?? .white }
}
