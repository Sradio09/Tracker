import UIKit

enum AppColors {

    // MARK: - Base
    static var background: UIColor { UIColor(named: "White") ?? .systemBackground }
    static var textPrimary: UIColor { UIColor(named: "Black") ?? .label }
    static var surface: UIColor { UIColor(named: "LightGray") ?? .secondarySystemBackground }
    static var inputBackground: UIColor { UIColor(named: "Background") ?? .tertiarySystemBackground }
    static var separator: UIColor { UIColor(named: "Grey") ?? .separator }
    static var searchField: UIColor { UIColor(named: "SearchField") ?? .searchField }
    static var searchText: UIColor { UIColor(named: "SearchText") ?? .searchText}
    static var tabBarSeparator: UIColor { UIColor(named: "TabBarSeparator") ?? .searchText}



    // MARK: - Accents

    static var accentBlue: UIColor { UIColor(named: "Blue") ?? .systemBlue }
    static var accentRed: UIColor { UIColor(named: "Red") ?? .systemRed }

    // MARK: - Tracker color palette (Create screen)

    static var selectionColors: [UIColor] {
        (1...18).compactMap { UIColor(named: "ColorSelection\($0)") }
    }

    // MARK: - Convenience
    static var primaryButtonBackground: UIColor { textPrimary }
    static var primaryButtonTitle: UIColor { background }
    static var disabledButtonBackground: UIColor { separator.withAlphaComponent(0.4) }
}
