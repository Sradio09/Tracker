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
        self.init(context: Self.makeViewContext(), delegate: delegate)
    }
    
    private static func makeViewContext() -> NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            assertionFailure("AppDelegate is not available")
            return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        }
        return appDelegate.persistentContainer.viewContext
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
        do {
            try frc.performFetch()
        } catch {
            assertionFailure("TrackerRecordStore FRC fetch failed: \(error)")
        }
        return frc
    }()
    
    // MARK: - Public API (без CoreData наружу)
    
    func fetchAllRecords() -> [TrackerRecord] {
        let objects = fetchedResultsController.fetchedObjects ?? []
        return objects.compactMap { record in
            guard
                let tracker = record.tracker,
                let trackerId = tracker.id,
                let date = record.date
            else { return nil }
            
            return TrackerRecord(trackerId: trackerId, date: date)
        }
    }
    
    func addRecord(date: Date, trackerId: UUID) throws {
        guard let tracker = try fetchTrackerCoreData(by: trackerId) else { return }
        
        let record = TrackerRecordCoreData(context: context)
        record.id = UUID()
        record.date = date
        record.tracker = tracker
        
        try context.save()
    }
    
    func deleteRecord(date: Date, trackerId: UUID) throws {
        let request = TrackerRecordCoreData.fetchRequest()
        request.sortDescriptors = []
        request.predicate = NSPredicate(format: "date == %@", date as NSDate)
        
        let records = try context.fetch(request)
        for record in records {
            if record.tracker?.id == trackerId {
                context.delete(record)
            }
        }
        
        try context.save()
    }
    
    // MARK: - Private
    
    private func fetchTrackerCoreData(by id: UUID) throws -> TrackerCoreData? {
        let request = TrackerCoreData.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        return try context.fetch(request).first
    }
}

// MARK: - NSFetchedResultsControllerDelegate

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

