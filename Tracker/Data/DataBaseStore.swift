import CoreData

final class DataBaseStore {

    static let shared = DataBaseStore()

    let persistentContainer: NSPersistentContainer

    private init() {
        let container = NSPersistentContainer(name: "TrackerModel")
        container.loadPersistentStores { _, error in
            if let error = error {
                assertionFailure("Unresolved Core Data error: \(error)")
            }
        }

        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true

        self.persistentContainer = container
    }

    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }

    func saveContext() {
        let context = viewContext
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save Core Data context: \(error)")
        }
    }
}

