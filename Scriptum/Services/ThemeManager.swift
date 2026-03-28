import SwiftUI
import Combine

final class ThemeManager: ObservableObject {
    @AppStorage("folio.theme") var theme: AppTheme = .dark {
        didSet { objectWillChange.send() }
    }

    var colorScheme: ColorScheme? {
        switch theme {
        case .dark:   return .dark
        case .light:  return .light
        case .system: return nil
        }
    }

    // Design Tokens matching HTML design
    static let bg          = Color(hex: "09100F")
    static let bg2         = Color(hex: "0D1614")
    static let glass       = Color(hex: "0D1614").opacity(0.45)
    static let t1          = Color(hex: "EEFAF6")
    static let t2          = Color(hex: "EEFAF6").opacity(0.55)
    static let t3          = Color(hex: "EEFAF6").opacity(0.28)
    static let gold        = Color(hex: "F5C842")
    static let goldDim     = Color(hex: "F5C842").opacity(0.18)
    static let teal        = Color(hex: "2DD4BF")
    static let tealDim     = Color(hex: "2DD4BF").opacity(0.14)
    static let rose        = Color(hex: "FB7185")
    static let sky         = Color(hex: "7DD3FC")
    static let lavender    = Color(hex: "C4B5FD")
    static let border      = Color.white.opacity(0.07)
    static let borderHov   = Color.white.opacity(0.18)
    static let cardBg      = Color.white.opacity(0.045)
    static let cardHover   = Color.white.opacity(0.08)
}

enum AppTheme: String, CaseIterable {
    case dark, light, system
    var label: String {
        switch self {
        case .dark:   return "Dark"
        case .light:  return "Light"
        case .system: return "System"
        }
    }
}
