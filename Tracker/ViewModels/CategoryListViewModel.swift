import Foundation

final class CategoryListViewModel {
    
    var onDataChanged: (() -> Void)?
    var onError: ((String) -> Void)?
    
    private let store: TrackerCategoryStore
    private(set) var selectedTitle: String?
    
    init(store: TrackerCategoryStore, selectedTitle: String? = nil) {
        self.store = store
        self.selectedTitle = selectedTitle
    }
    
    func numberOfSections() -> Int { store.numberOfSections() }
    
    func numberOfRows(in section: Int) -> Int {
        store.numberOfRowsInSection(section)
    }
    
    func category(at indexPath: IndexPath) -> TrackerCategory {
        let obj = store.object(at: indexPath)
        let title = obj.title ?? ""
        return TrackerCategory(title: title)
    }
    
    func categoryTitle(at indexPath: IndexPath) -> String {
        category(at: indexPath).title
    }
    
    func isSelected(at indexPath: IndexPath) -> Bool {
        category(at: indexPath).title == selectedTitle
    }
    
    func didSelectRow(at indexPath: IndexPath) -> TrackerCategory {
        let cat = category(at: indexPath)
        selectedTitle = cat.title
        onDataChanged?()
        return cat
    }
    
    func deleteCategory(at indexPath: IndexPath) {
        do {
            let deletingTitle = categoryTitle(at: indexPath)
            try store.deleteCategory(at: indexPath)
            
            if selectedTitle == deletingTitle {
                selectedTitle = nil
            }
            onDataChanged?()
        } catch {
            onError?("Не удалось удалить категорию")
        }
    }
    
    func updateCategory(at indexPath: IndexPath, newTitle: String) {
        do {
            let oldTitle = categoryTitle(at: indexPath)
            try store.updateCategory(at: indexPath, newTitle: newTitle)
            
            if selectedTitle == oldTitle {
                selectedTitle = newTitle
            }
            onDataChanged?()
        } catch {
            onError?("Не удалось сохранить категорию")
        }
    }
}

