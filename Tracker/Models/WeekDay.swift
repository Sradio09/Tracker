import Foundation

enum WeekDay: Int, CaseIterable {
    case monday = 0
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday
    case sunday

    var localizedShort: String {
        switch self {
        case .monday: return NSLocalizedString("weekday.monday.short", comment: "Mon short")
        case .tuesday: return NSLocalizedString("weekday.tuesday.short", comment: "Tue short")
        case .wednesday: return NSLocalizedString("weekday.wednesday.short", comment: "Wed short")
        case .thursday: return NSLocalizedString("weekday.thursday.short", comment: "Thu short")
        case .friday: return NSLocalizedString("weekday.friday.short", comment: "Fri short")
        case .saturday: return NSLocalizedString("weekday.saturday.short", comment: "Sat short")
        case .sunday: return NSLocalizedString("weekday.sunday.short", comment: "Sun short")
        }
    }

    var localizedFull: String {
        switch self {
        case .monday: return NSLocalizedString("weekday.monday.full", comment: "Monday full")
        case .tuesday: return NSLocalizedString("weekday.tuesday.full", comment: "Tuesday full")
        case .wednesday: return NSLocalizedString("weekday.wednesday.full", comment: "Wednesday full")
        case .thursday: return NSLocalizedString("weekday.thursday.full", comment: "Thursday full")
        case .friday: return NSLocalizedString("weekday.friday.full", comment: "Friday full")
        case .saturday: return NSLocalizedString("weekday.saturday.full", comment: "Saturday full")
        case .sunday: return NSLocalizedString("weekday.sunday.full", comment: "Sunday full")
        }
    }

    // MARK: - CoreData schedule

    private var bitIndex: Int { rawValue }

    static func mask(from days: [WeekDay]) -> Int16 {
        var value: Int16 = 0
        for d in Set(days) {
            value |= Int16(1 << d.bitIndex)
        }
        return value
    }

    static func days(from mask: Int16) -> [WeekDay] {
        WeekDay.allCases.filter { day in
            (mask & Int16(1 << day.bitIndex)) != 0
        }
    }
}

