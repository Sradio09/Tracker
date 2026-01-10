import UIKit

enum CreateTrackerSection: Int, CaseIterable {
    case emoji
    case color
    
    var title: String {
        switch self {
        case .emoji: return NSLocalizedString("create_tracker.section.emoji", comment: "Emoji section")
        case .color: return NSLocalizedString("create_tracker.section.color", comment: "Color section")
        }
    }
}

enum CreateTrackerItem: Hashable {
    case emoji(String)
    case color(UIColor)
}
