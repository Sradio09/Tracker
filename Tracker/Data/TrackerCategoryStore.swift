import UIKit
import CoreData

final class TrackerCategoryStore: NSObject {
    
    weak var delegate: StoreUpdateDelegate?
    
    private let context: NSManagedObjectContext
    private var insertedIndexes: IndexSet?
    private var deletedIndexes: IndexSet?
    
    // MARK: - Init
    
    init(context: NSManagedObjectContext, delegate: StoreUpdateDelegate? = nil) {
        self.context = context
        self.delegate = delegate
        super.init()
        _ = fetchedResultsController
    }
    
    convenience init(delegate: StoreUpdateDelegate?) {
        self.init(context: Self.makeViewContext(), delegate: delegate)
    }
    
    convenience override init() {
        self.init(context: Self.makeViewContext(), delegate: nil)
    }
    
    private static func makeViewContext() -> NSManagedObjectContext {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            assertionFailure("AppDelegate is not available")
            return NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        }
        return appDelegate.persistentContainer.viewContext
    }
    
    // MARK: - FRC
    
    private lazy var fetchedResultsController: NSFetchedResultsController<TrackerCategoryCoreData> = {
        let fetchRequest = TrackerCategoryCoreData.fetchRequest()
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
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
            assertionFailure("TrackerCategoryStore FRC fetch failed: \(error)")
        }
        return frc
    }()
    
    // MARK: - Data for UITableViewDataSource
    
    func numberOfSections() -> Int {
        fetchedResultsController.sections?.count ?? 0
    }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func object(at indexPath: IndexPath) -> TrackerCategoryCoreData {
        fetchedResultsController.object(at: indexPath)
    }
    
    
    // MARK: - CRUD
    
    func addCategory(title: String) throws {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let obj = TrackerCategoryCoreData(context: context)
        obj.title = trimmed
        try context.save()
    }
    
    func deleteCategory(at indexPath: IndexPath) throws {
        let obj = fetchedResultsController.object(at: indexPath)
        context.delete(obj)
        try context.save()
    }
    func updateCategory(at indexPath: IndexPath, newTitle: String) throws {
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let obj = fetchedResultsController.object(at: indexPath)
        obj.title = trimmed
        try context.save()
    }
    
}

extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexes = []
        deletedIndexes = []
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

