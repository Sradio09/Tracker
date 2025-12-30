import Foundation
import UIKit

final class TrackersViewModel {
    
    enum SectionModel {
        case categorized(title: String, trackers: [Tracker])
        case uncategorized(trackers: [Tracker])
        
        var trackers: [Tracker] {
            switch self {
            case .categorized(_, let trackers): return trackers
            case .uncategorized(let trackers): return trackers
            }
        }
        
        var title: String? {
            switch self {
            case .categorized(let title, _): return title
            case .uncategorized: return nil
            }
        }
    }
    
    private(set) var categories: [TrackerCategory] = []
    private(set) var completedTrackers: [TrackerRecord] = []
    private(set) var sections: [SectionModel] = []
    
    private(set) var currentDate: Date = Date()
    private var currentSearchText: String = ""
    
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
    
    func reloadFromStores() {
        categories = buildCategoriesFromCoreData()
        completedTrackers = recordStore.fetchAllRecords()
        applyFilter()
    }
    
    func addTracker(_ tracker: Tracker, categoryTitle: String?) {
        do {
            let category = try categoryCoreDataIfNeeded(with: categoryTitle)
            
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
    
    func deleteTracker(_ id: UUID) {
        do {
            try trackerStore.deleteTracker(with: id)
        } catch {
            assertionFailure("Не удалось удалить трекер: \(error)")
        }
        reloadFromStores()
    }
    
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
    
    func filterBy(date: Date) {
        currentDate = date
        applyFilter()
    }
    
    func filterBy(search text: String) {
        currentSearchText = text
        applyFilter()
    }
    
    private func applyFilter() {
        let weekday = currentDate.weekday
        let search = currentSearchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        var resultSections: [SectionModel] = categories.compactMap { category in
            let filtered = category.trackers.filter { tracker in
                let matchesDay = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
                let matchesSearch = search.isEmpty || tracker.name.lowercased().contains(search)
                return matchesDay && matchesSearch
            }
            guard !filtered.isEmpty else { return nil }
            return .categorized(title: category.title, trackers: filtered)
        }
        
        let uncategorized = fetchUncategorizedTrackers().filter { tracker in
            let matchesDay = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)
            let matchesSearch = search.isEmpty || tracker.name.lowercased().contains(search)
            return matchesDay && matchesSearch
        }
        
        if !uncategorized.isEmpty {
            resultSections.append(.uncategorized(trackers: uncategorized))
        }
        
        sections = resultSections
    }
    
    // MARK: - Data for VC
    
    func numberOfSections() -> Int { sections.count }
    func numberOfItems(in section: Int) -> Int { sections[section].trackers.count }
    func sectionTitle(_ section: Int) -> String? { sections[section].title }
    
    func tracker(at indexPath: IndexPath) -> Tracker {
        sections[indexPath.section].trackers[indexPath.item]
    }
    
    func isUncategorizedSection(_ section: Int) -> Bool {
        if case .uncategorized = sections[section] { return true }
        return false
    }
    
    // MARK: - CoreData -> Domain mapping
    
    private func buildCategoriesFromCoreData() -> [TrackerCategory] {
        var result: [TrackerCategory] = []
        
        let sectionsCount = categoryStore.numberOfSections()
        for section in 0..<sectionsCount {
            let rowsCount = categoryStore.numberOfRowsInSection(section)
            for row in 0..<rowsCount {
                let categoryCD = categoryStore.object(at: IndexPath(row: row, section: section))
                
                guard let titleRaw = categoryCD.title?.trimmingCharacters(in: .whitespacesAndNewlines),
                      !titleRaw.isEmpty else { continue }
                
                let trackersSet = (categoryCD.value(forKey: "trackers") as? Set<TrackerCoreData>) ?? []
                let trackers = trackersSet
                    .compactMap(Self.mapTrackerCoreDataToDomain)
                    .sorted { $0.name.lowercased() < $1.name.lowercased() }
                
                result.append(TrackerCategory(title: titleRaw, trackers: trackers))
            }
        }
        
        result.sort { $0.title.lowercased() < $1.title.lowercased() }
        return result
    }
    
    private func fetchUncategorizedTrackers() -> [Tracker] {
        var trackers: [Tracker] = []
        
        let secCount = trackerStore.numberOfSections
        for section in 0..<secCount {
            let rows = trackerStore.numberOfRowsInSection(section)
            for row in 0..<rows {
                let obj = trackerStore.object(at: IndexPath(row: row, section: section))
                if obj.category == nil {
                    if let mapped = Self.mapTrackerCoreDataToDomain(obj) {
                        trackers.append(mapped)
                    }
                }
            }
        }
        
        return trackers.sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
    
    private func categoryCoreDataIfNeeded(with title: String?) throws -> TrackerCategoryCoreData? {
        guard let title = title?.trimmingCharacters(in: .whitespacesAndNewlines),
              !title.isEmpty else { return nil }
        
        let sectionsCount = categoryStore.numberOfSections()
        for section in 0..<sectionsCount {
            let rowsCount = categoryStore.numberOfRowsInSection(section)
            for row in 0..<rowsCount {
                let obj = categoryStore.object(at: IndexPath(row: row, section: section))
                if (obj.title ?? "") == title { return obj }
            }
        }
        
        try categoryStore.addCategory(title: title)
        
        let sectionsCount2 = categoryStore.numberOfSections()
        for section in 0..<sectionsCount2 {
            let rowsCount = categoryStore.numberOfRowsInSection(section)
            for row in 0..<rowsCount {
                let obj = categoryStore.object(at: IndexPath(row: row, section: section))
                if (obj.title ?? "") == title { return obj }
            }
        }
        
        throw NSError(
            domain: "TrackerCategoryStore",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Не удалось создать категорию"]
        )
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
        for day in Set(days) { mask |= Int16(1 << bitIndex(for: day)) }
        return mask
    }
    
    private static func days(from mask: Int16) -> [WeekDay] {
        WeekDay.allCases.filter { day in (mask & Int16(1 << bitIndex(for: day))) != 0 }
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
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
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
        let bStr = String(s.dropFirst(4))
        
        let r = CGFloat(Int(rStr, radix: 16) ?? 0) / 255.0
        let g = CGFloat(Int(gStr, radix: 16) ?? 0) / 255.0
        let b = CGFloat(Int(bStr, radix: 16) ?? 0) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
}

