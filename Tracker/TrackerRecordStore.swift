import UIKit
import CoreData

final class TrackerRecordStore: NSObject {

    weak var delegate: StoreUpdateDelegate?

    private let context: NSManagedObjectContext

    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?

    init(context: NSManagedObjectContext, delegate: StoreUpdateDelegate?) {
        self.context = context
        self.delegate = delegate
        super.init()
    }

    convenience init(delegate: StoreUpdateDelegate?) {
        self.init(
            context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext,
            delegate: delegate
        )
    }

    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerRecordCoreData> = {
        let fetchRequest = TrackerRecordCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]

        let frc = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: context,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        frc.delegate = self
        try? frc.performFetch()
        return frc
    }()

    // MARK: - Public API (без CoreData наружу)

    func fetchAllRecords() -> [TrackerRecord] {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: true)]
        guard let records = try? context.fetch(request) else { return [] }

        return records.compactMap { rec in
            // relationship "tracker" -> TrackerCoreData
            let tracker = rec.value(forKey: "tracker") as? TrackerCoreData
            guard let trackerId = tracker?.id, let date = rec.date else { return nil }
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }

    func addRecord(date: Date, trackerId: UUID) throws {
        guard let tracker = try fetchTracker(by: trackerId) else { return }

        let record = TrackerRecordCoreData(context: context)
        record.id = UUID()
        record.date = date

        record.setValue(tracker, forKey: "tracker")

        try context.save()
    }

    func deleteRecord(date: Date, trackerId: UUID) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)

        let records = try context.fetch(request)
        for rec in records {
            let tracker = rec.value(forKey: "tracker") as? TrackerCoreData
            if tracker?.id == trackerId {
                context.delete(rec)
            }
        }
        try context.save()
    }

    // MARK: - Private

    private func fetchTracker(by id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}

extension TrackerRecordStore: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = IndexSet()
        deletedIndexes = IndexSet()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?
    ) {
        switch type {
        case .delete:
            if let indexPath { deletedIndexes?.insert(indexPath.row) }
        case .insert:
            if let newIndexPath { insertedIndexes?.insert(newIndexPath.row) }
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        delegate?.didUpdate(StoreUpdate(
            insertedIndexes: insertedIndexes ?? [],
            deletedIndexes: deletedIndexes ?? []
        ))
        insertedIndexes = nil
        deletedIndexes = nil
    }
}

