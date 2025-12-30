enum WeekDay: String, CaseIterable {
    case monday = "Пн"
    case tuesday = "Вт"
    case wednesday = "Ср"
    case thursday = "Чт"
    case friday = "Пт"
    case saturday = "Сб"
    case sunday = "Вс"
    
    var fullName: String {
        switch self {
        case .monday: return "Понедельник"
        case .tuesday: return "Вторник"
        case .wednesday: return "Среда"
        case .thursday: return "Четверг"
        case .friday: return "Пятница"
        case .saturday: return "Суббота"
        case .sunday: return "Воскресенье"
        }
    }
    
    // MARK: - CoreData schedule (Int16 bitmask)
    
    private var bitIndex: Int {
        switch self {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
    
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

