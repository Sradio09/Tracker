import Foundation

struct StoreUpdate {
    let insertedIndexes: IndexSet
    let deletedIndexes: IndexSet
}

protocol StoreUpdateDelegate: AnyObject {
    func didUpdate(_ update: StoreUpdate)
}

