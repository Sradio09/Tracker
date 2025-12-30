import UIKit

enum CreateTrackerSection: Int, CaseIterable {
    case emoji
    case color
    
    var title: String {
        switch self {
        case .emoji: return "Emoji"
        case .color: return "Цвет"
        }
    }
}

enum CreateTrackerItem: Hashable {
    case emoji(String)
    case color(UIColor)
}
