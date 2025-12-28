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
        self.init(
            context: (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext,
            delegate: delegate
        )
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
        try? frc.performFetch()
        return frc
    }()
    
    // MARK: - Public API (без утечки CoreData в UI)
    
    func fetchCategories() -> [TrackerCategory] {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        guard let categories = try? context.fetch(request) else { return [] }
        
        return categories.map { categoryCD in
            let title = categoryCD.title ?? "Без категории"
            
            let trackersSet = (categoryCD.value(forKey: "trackers") as? Set<TrackerCoreData>) ?? []
            let trackers = trackersSet
                .map(mapToTracker)
                .sorted { $0.name.lowercased() < $1.name.lowercased() }
            
            return TrackerCategory(title: title, trackers: trackers)
        }
    }
    
    func addTracker(_ tracker: Tracker, to categoryTitle: String, isPinned: Bool = false) throws {
        let category = try findOrCreateCategory(title: categoryTitle)
        
        let obj = TrackerCoreData(context: context)
        obj.id = tracker.id
        obj.name = tracker.name
        obj.emoji = tracker.emoji
        obj.colorHex = UIColorMarshalling.hexString(from: tracker.color)
        obj.schedule = WeekDay.mask(from: tracker.schedule)
        obj.setValue(category, forKey: "category")
        
        try context.save()
    }
    
    func deleteTracker(withId id: UUID) throws {
        let request = TrackerCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        request.fetchLimit = 1
        
        if let obj = try context.fetch(request).first {
            context.delete(obj)
            try context.save()
        }
    }
    
    // MARK: - Private
    
    private func findOrCreateCategory(title: String) throws -> TrackerCategoryCoreData {
        let request = TrackerCategoryCoreData.fetchRequest()
        request.predicate = NSPredicate(format: "title == %@", title)
        request.fetchLimit = 1
        
        if let existing = try context.fetch(request).first {
            return existing
        }
        
        let created = TrackerCategoryCoreData(context: context)
        created.title = title
        try context.save()
        return created
    }
    
    private func mapToTracker(_ obj: TrackerCoreData) -> Tracker {
        let id = obj.id ?? UUID()
        let name = obj.name ?? ""
        let emoji = obj.emoji ?? "🙂"
        let color = UIColorMarshalling.color(from: obj.colorHex)
        let schedule = WeekDay.days(from: obj.schedule)
        
        return Tracker(
            id: id,
            name: name,
            color: color,
            emoji: emoji,
            schedule: schedule
        )
    }
}

// MARK: - NSFetchedResultsControllerDelegate

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

// MARK: - UIColor <-> Hex (private helper inside Store layer)

private enum UIColorMarshalling {
    
    static func hexString(from color: UIColor) -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        
        let ri = Int(round(r * 255))
        let gi = Int(round(g * 255))
        let bi = Int(round(b * 255))
        
        return String(format: "#%02X%02X%02X", ri, gi, bi)
    }
    
    static func color(from hex: String?) -> UIColor {
        guard let hex else { return .systemBlue }
        var s = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 else { return .systemBlue }
        
        let rStr = String(s.prefix(2))
        let gStr = String(s.dropFirst(2).prefix(2))
        let bStr = String(s.dropFirst(4).prefix(2))
        
        let r = CGFloat(Int(rStr, radix: 16) ?? 0) / 255.0
        let g = CGFloat(Int(gStr, radix: 16) ?? 0) / 255.0
        let b = CGFloat(Int(bStr, radix: 16) ?? 0) / 255.0
        
        return UIColor(red: r, green: g, blue: b, alpha: 1)
    }
}

