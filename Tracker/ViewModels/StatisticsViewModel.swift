import Foundation
import CoreData

struct StatisticsMetrics {
    let completed: Int
    let bestPeriod: Int
    let perfectDays: Int
    let average: Int
}

final class StatisticsViewModel {

    private let context: NSManagedObjectContext
    private let calendar = Calendar.current

    init(context: NSManagedObjectContext = DataBaseStore.shared.persistentContainer.viewContext) {
        self.context = context
    }

    func loadMetrics() -> StatisticsMetrics {
        let request = NSFetchRequest<NSDictionary>(entityName: "TrackerRecordCoreData")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["date"]
        request.returnsDistinctResults = false

        let dates: [Date] = (try? context.fetch(request).compactMap { $0["date"] as? Date }) ?? []

        let completed = dates.count

        guard completed > 0 else {
            return StatisticsMetrics(completed: 0, bestPeriod: 0, perfectDays: 0, average: 0)
        }

        var perDay: [Date: Int] = [:]
        for d in dates {
            let day = calendar.startOfDay(for: d)
            perDay[day, default: 0] += 1
        }

        let bestPeriod = perDay.values.max() ?? 0
        let perfectDays = perDay.values.filter { $0 == bestPeriod }.count
        let average = Int(round(Double(completed) / Double(perDay.keys.count)))

        return StatisticsMetrics(
            completed: completed,
            bestPeriod: bestPeriod,
            perfectDays: perfectDays,
            average: average
        )
    }
}

