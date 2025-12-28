import UIKit
import CoreData

final class TrackerCategoryStore: NSObject {
    
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
        try? frc.performFetch()
        return frc
    }()
    
    // MARK: - Data for UITableViewDataSource
    
    var numberOfSections: Int { fetchedResultsController.sections?.count ?? 0 }
    
    func numberOfRowsInSection(_ section: Int) -> Int {
        fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func object(at indexPath: IndexPath) -> TrackerCategoryCoreData {
        fetchedResultsController.object(at: indexPath)
    }
    
    // MARK: - CRUD
    
    func addCategory(title: String) throws {
        let obj = TrackerCategoryCoreData(context: context)
        obj.title = title
        try context.save()
    }
    
    func deleteCategory(at indexPath: IndexPath) throws {
        let obj = fetchedResultsController.object(at: indexPath)
        context.delete(obj)
        try context.save()
    }
}

// MARK: - NSFetchedResultsControllerDelegate (как в уроке Notepad)
extension TrackerCategoryStore: NSFetchedResultsControllerDelegate {
    
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

