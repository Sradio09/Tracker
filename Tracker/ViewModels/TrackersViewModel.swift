import Foundation
import UIKit

final class TrackersViewModel {

    // MARK: - Stored data

    private(set) var categories: [TrackerCategory] = []
    private(set) var completedTrackers: [TrackerRecord] = []
    private(set) var filteredTrackers: [Tracker] = []
    private(set) var currentDate: Date = Date()
    private var currentSearchText: String = ""

    // MARK: - Stores (UI НЕ знает про CoreData)

    private let trackerStore: TrackerStore
    private let recordStore: TrackerRecordStore

    init(delegate: StoreUpdateDelegate?) {
        self.trackerStore = TrackerStore(delegate: delegate)
        self.recordStore = TrackerRecordStore(delegate: delegate)

        reloadFromStores()
        filterBy(date: Date())
    }

    func reloadFromStores() {
        categories = trackerStore.fetchCategories()
        completedTrackers = recordStore.fetchAllRecords()
        applyFilter()
    }

    // MARK: - Работа с трекерами / категориями

    func addTracker(_ tracker: Tracker, to categoryTitle: String) {
        do {
            try trackerStore.addTracker(tracker, to: categoryTitle)
        } catch {
            assertionFailure("Не удалось сохранить трекер: \(error)")
        }

        reloadFromStores()
    }

    // MARK: - Завершение трекера

    func completeTracker(_ trackerId: UUID, on date: Date) {
        guard !isTrackerCompleted(trackerId, on: date) else { return }

        do {
            try recordStore.addRecord(date: date, trackerId: trackerId)
        } catch {
            assertionFailure("Не удалось сохранить запись завершения: \(error)")
        }

        reloadFromStores()
    }

    func uncompleteTracker(_ trackerId: UUID, on date: Date) {
        do {
            try recordStore.deleteRecord(date: date, trackerId: trackerId)
        } catch {
            assertionFailure("Не удалось удалить запись завершения: \(error)")
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

    // MARK: - Фильтрация

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
            // если расписание пустое — считаем нерегулярным событием (показываем всегда)
            let matchesDay = tracker.schedule.isEmpty || tracker.schedule.contains(weekday)

            let matchesSearch = currentSearchText.isEmpty ||
                tracker.name.lowercased().contains(currentSearchText)

            return matchesDay && matchesSearch
        }
    }
}

