import Foundation
import UIKit

final class TrackersViewModel {
    // MARK: - Stored data
    
    private(set) var categories: [TrackerCategory] = []
    private(set) var completedTrackers: [TrackerRecord] = []
    private(set) var filteredTrackers: [Tracker] = []
    private(set) var currentDate: Date = Date()
    private var currentSearchText: String = ""
    
    // MARK: - Работа с трекерами / категориями
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        if let index = categories.firstIndex(where: { $0.title == categoryTitle }) {
            var existing = categories[index].trackers
            existing.append(tracker)
            categories[index] = TrackerCategory(title: categoryTitle, trackers: existing)
        } else {
            categories.append(TrackerCategory(title: categoryTitle, trackers: [tracker]))
        }
        
        applyFilter()
    }
    
    // MARK: - Завершение трекера
    
    func completeTracker(_ trackerId: UUID, on date: Date) {
        guard !isTrackerCompleted(trackerId, on: date) else { return }
        completedTrackers.append(TrackerRecord(trackerId: trackerId, date: date))
    }
    
    func uncompleteTracker(_ trackerId: UUID, on date: Date) {
        completedTrackers.removeAll {
            $0.trackerId == trackerId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func isTrackerCompleted(_ trackerId: UUID, on date: Date) -> Bool {
        completedTrackers.contains {
            $0.trackerId == trackerId && Calendar.current.isDate($0.date, inSameDayAs: date)
        }
    }
    
    func completedCount(for trackerId: UUID) -> Int {
        completedTrackers.filter { $0.trackerId == trackerId }.count
    }
    
    // MARK: - Загрузка тестовых данных
    
    func loadTestData() {
        let tracker1 = Tracker(
            id: UUID(),
            name: "Пробежка",
            color: .systemBlue,
            emoji: "🏃‍♂️",
            schedule: [.monday, .wednesday, .friday]
        )
        
        let tracker2 = Tracker(
            id: UUID(),
            name: "Медитация",
            color: .systemGreen,
            emoji: "🧘‍♀️",
            schedule: WeekDay.allCases
        )
        
        categories = [TrackerCategory(title: "Здоровье", trackers: [tracker1, tracker2])]
        applyFilter()
    }
    
    // MARK: - Публичные методы фильтрации
    
    func filterBy(date: Date) {
        currentDate = date
        applyFilter()
    }
    
    func filterBy(search text: String) {
        currentSearchText = text.lowercased()
        applyFilter()
    }
    
    // MARK: - Приватная логика фильтрации
    
    private func applyFilter() {
        // ✅ Для проверки заглушки: 1-го числа любого месяца список всегда пустой
        if Calendar.current.component(.day, from: currentDate) == 1 {
            filteredTrackers = []
            return
        }
        
        guard let weekday = weekday(from: currentDate) else {
            filteredTrackers = []
            return
        }
        
        let allTrackers = categories.flatMap { $0.trackers }
        
        filteredTrackers = allTrackers.filter { tracker in
            let matchesDay = tracker.schedule.contains(weekday)
            let matchesSearch = currentSearchText.isEmpty ||
            tracker.name.lowercased().contains(currentSearchText)
            return matchesDay && matchesSearch
        }
    }
    
    private func weekday(from date: Date) -> WeekDay? {
        let weekdayIndex = Calendar.current.component(.weekday, from: date)
        switch weekdayIndex {
        case 1: return .sunday
        case 2: return .monday
        case 3: return .tuesday
        case 4: return .wednesday
        case 5: return .thursday
        case 6: return .friday
        case 7: return .saturday
        default: return nil
        }
    }
}

