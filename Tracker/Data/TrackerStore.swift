import UIKit
import CoreData

final class TrackerStore: NSObject {
    
    weak var delegate: StoreUpdateDelegate?
    
    private let context: NSManagedObjectContext
    
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    
    init(context: NSManagedObjectContext, delegate: StoreUpdateDelegate?) {
        self.context = context
        self.delegate = delegate
        super.init()
        _ = fetchedResultsController
    }
    
    convenience init(delegate: StoreUpdateDelegate?) {
        self.init(context: Self.makeViewContext(), delegate: delegate)
    }
    
    private static func makeViewContext() -> NSManagedObjectContext {
        DataBaseStore.shared.viewContext
    }
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCoreData> = {
        let fetchRequest = TrackerCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
        
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
            assertionFailure("TrackerStore FRC fetch failed: \(error)")
        }
        return frc
    }()
    
    var numberOfSections: Int { fetchedResultsController.sections?.count ?? 0 }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func object(at indexPath: IndexPath) -> TrackerCoreData {
        fetchedResultsController.object(at: indexPath)
    }
    
    func addNewTracker(
        id: UUID,
        name: String,
        emoji: String,
        colorHex: String,
        schedule: Int16,
        isPinned: Bool,
        category: TrackerCategoryCoreData?
    ) throws {
        let tracker = TrackerCoreData(context: context)
        tracker.id = id
        tracker.name = name
        tracker.emoji = emoji
        tracker.colorHex = colorHex
        tracker.schedule = schedule
        tracker.isPinned = isPinned
        tracker.category = category
        try context.save()
    }
    func updateTracker(
        id: UUID,
        name: String,
        emoji: String,
        colorHex: String,
        schedule: Int16,
        isPinned: Bool,
        category: TrackerCategoryCoreData?
    ) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1

        guard let tracker = try context.fetch(request).first else { return }
        tracker.name = name
        tracker.emoji = emoji
        tracker.colorHex = colorHex
        tracker.schedule = schedule
        tracker.isPinned = isPinned
        tracker.category = category
        try context.save()
    }


    
    func deleteTracker(at indexPath: IndexPath) throws {
        let tracker = fetchedResultsController.object(at: indexPath)
        context.delete(tracker)
        try context.save()
    }
    
    func deleteTracker(with id: UUID) throws {
        let secCount = numberOfSections
        for section in 0..<secCount {
            let rows = numberOfRowsInSection(section)
            for row in 0..<rows {
                let obj = object(at: IndexPath(row: row, section: section))
                if obj.id == id {
                    context.delete(obj)
                    try context.save()
                    return
                }
            }
        }
    }

    func setPinned(_ isPinned: Bool, for trackerId: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", trackerId as CVarArg)
        request.fetchLimit = 1

        guard let tracker = try context.fetch(request).first else { return }
        tracker.isPinned = isPinned
        try context.save()
    }
}

extension TrackerStore: NSFetchedResultsControllerDelegate {
    
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

