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
        category: TrackerCategoryCoreData
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

    func deleteTracker(at indexPath: IndexPath) throws {
        let tracker = fetchedResultsController.object(at: indexPath)
        context.delete(tracker)
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

