import Foundation

extension Date {
    var weekday: WeekDay {
        let value = Calendar.current.component(.weekday, from: self)
        
        switch value {
        case 2: return .monday       // Пн
        case 3: return .tuesday      // Вт
        case 4: return .wednesday    // Ср
        case 5: return .thursday     // Чт
        case 6: return .friday       // Пт
        case 7: return .saturday     // Сб
        case 1: fallthrough
        default: return .sunday      // Вс
        }
    }
}

