import Foundation
import UIKit

final class TrackersViewModel {
    
    // MARK: - Stored data
    
    private(set) var categories: [TrackerCategory] = []
    private(set) var completedTrackers: [TrackerRecord] = []
    private(set) var filteredTrackers: [Tracker] = []
    
    private(set) var currentDate: Date = Date()
    private var currentSearchText: String = ""
    
    // MARK: - Stores
    
    private let trackerStore: TrackerStore
    private let categoryStore: TrackerCategoryStore
    private let recordStore: TrackerRecordStore
    
    init(delegate: StoreUpdateDelegate?) {
        self.trackerStore = TrackerStore(delegate: delegate)
        self.categoryStore = TrackerCategoryStore(delegate: delegate)
        self.recordStore = TrackerRecordStore(delegate: delegate)
        
        reloadFromStores()
        filterBy(date: Date())
    }
    
    // MARK: - Reload
    
    func reloadFromStores() {
        categories = buildCategoriesFromCoreData()
        completedTrackers = recordStore.fetchAllRecords()
        applyFilter()
    }
    
    // MARK: - Create tracker
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        do {
            let category = try findOrCreateCategoryCoreData(with: categoryTitle)
            
            try trackerStore.addNewTracker(
                id: tracker.id,
                name: tracker.name,
                emoji: tracker.emoji,
                colorHex: Self.hexString(from: tracker.color),
                schedule: Self.scheduleMask(from: tracker.schedule),
                isPinned: false,
                category: category
            )
        } catch {
            assertionFailure("Не удалось сохранить трекер: \(error)")
        }
        
        reloadFromStores()
    }
    
    // MARK: - Completion (records)
    
    func completeTracker(_ trackerId: UUID, on date: Date) {
        guard !isTrackerCompleted(trackerId, on: date) else { return }
        
        do {
            try recordStore.addRecord(date: date, trackerId: trackerId)
        } catch {
            assertionFailure("Не удалось сохранить запись выполнения: \(error)")
        }
        
        reloadFromStores()
    }
    
    func uncompleteTracker(_ trackerId: UUID, on date: Date) {
        do {
            try recordStore.deleteRecord(date: date, trackerId: trackerId)
        } catch {
            assertionFailure("Не удалось удалить запись выполнения: \(error)")
        }
        
        reloadFromStores()
    }
    
    func isTrackerCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        completedTrackers.contains {
            $0.trackerId == trackerId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func completedCount(for trackerId: UUID) -> Int {
        completedTrackers.filter { $0.trackerId == trackerId }.count
    }
    
    // MARK: - Filtering
    
    func filterBy(date: Date) {
        currentDate = date
        applyFilter()
    }
    
    func filterBy(search text: String) {
        currentSearchText = text.lowercased()
        applyFilter()
    }
    
    private func applyFilter() {
        let weekday = currentDate.weekday
        
        let allTrackers = categories.flatMap { $0.trackers }
        
        filteredTrackers = allTrackers.filter { tracker in
            let matchesDay = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
            
            let matchesSearch = currentSearchText.isEmpty ||
            tracker.name.lowercased().contains(currentSearchText)
            
            return matchesDay && matchesSearch
        }
    }
    
    // MARK: - CoreData -> Domain mapping (через Store, без CoreData импортов в UI)
    
    private func buildCategoriesFromCoreData() -> [TrackerCategory] {
        var result: [TrackerCategory] = []
        
        let sections = categoryStore.numberOfSections
        
        for section in 0..<sections {
            let rows = categoryStore.numberOfRowsInSection(section)
            
            for row in 0..<rows {
                let categoryCD = categoryStore.object(at: IndexPath(row: row, section: section))
                let title = categoryCD.title ?? "Без категории"
                
                let trackersSet = (categoryCD.value(forKey: "trackers") as? Set<TrackerCoreData>) ?? []
                let trackers = trackersSet
                    .compactMap(Self.mapTrackerCoreDataToDomain)
                    .sorted { $0.name.lowercased() < $1.name.lowercased() }
                
                result.append(TrackerCategory(title: title, trackers: trackers))
            }
        }
        
        result.sort { $0.title.lowercased() < $1.title.lowercased() }
        return result
    }
    
    private func findOrCreateCategoryCoreData(with title: String) throws -> TrackerCategoryCoreData {
        let sections = categoryStore.numberOfSections
        for section in 0..<sections {
            let rows = categoryStore.numberOfRowsInSection(section)
            for row in 0..<rows {
                let obj = categoryStore.object(at: IndexPath(row: row, section: section))
                if (obj.title ?? "") == title {
                    return obj
                }
            }
        }
        
        try categoryStore.addCategory(title: title)
        
        let sections2 = categoryStore.numberOfSections
        for section in 0..<sections2 {
            let rows = categoryStore.numberOfRowsInSection(section)
            for row in 0..<rows {
                let obj = categoryStore.object(at: IndexPath(row: row, section: section))
                if (obj.title ?? "") == title {
                    return obj
                }
            }
        }
        
        throw NSError(domain: "TrackerCategoryStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Не удалось создать категорию"])
    }
    
    // MARK: - Helpers
    
    private static func mapTrackerCoreDataToDomain(_ obj: TrackerCoreData) -> Tracker? {
        guard let id = obj.id else { return nil }
        
        let name = obj.name ?? ""
        let emoji = obj.emoji ?? "🙂"
        let color = color(fromHex: obj.colorHex)
        let schedule = days(from: obj.schedule)
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
    
    private static func scheduleMask(from days: [WeekDay]) -> Int16 {
        var mask: Int16 = 0
        for day in Set(days) {
            mask |= Int16(1 << bitIndex(for: day))
        }
        return mask
    }
    
    private static func days(from mask: Int16) -> [WeekDay] {
        WeekDay.allCases.filter { day in
            (mask & Int16(1 << bitIndex(for: day))) != 0
        }
    }
    
    private static func bitIndex(for day: WeekDay) -> Int {
        switch day {
        case .monday: return 0
        case .tuesday: return 1
        case .wednesday: return 2
        case .thursday: return 3
        case .friday: return 4
        case .saturday: return 5
        case .sunday: return 6
        }
    }
    
    private static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
    
    private static func color(fromHex hex: String?) -> UIColor {
        guard var s = hex?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else {
            return .systemBlue
        }
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 else { return .systemBlue }
        
        let rStr = String(s.prefix(2))
        let gStr = String(s.dropFirst(2).prefix(2))
        let bStr = String(s.dropFirst(4).prefix(2))
        
        let r = CGFloat(Int(rStr, radix: 16) ?? 0) / 255.0
        let g = CGFloat(Int(gStr, radix: 16) ?? 0) / 255.0
        let b = CGFloat(Int(bStr, radix: 16) ?? 0) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

