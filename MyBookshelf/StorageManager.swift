import Foundation
import CoreData

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let coreDataManager: CoreDataManager
    
    private init() {
        self.coreDataManager = CoreDataManager.shared
    }
    
    func fetchShelves(completion: @escaping (Result<[Shelf], Error>) -> Void) {
        coreDataManager.fetchShelves(completion: completion)
    }
    
    func addShelf(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.addShelf(name: name, completion: completion)
    }
    
    func updateShelf(id: UUID, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.updateShelf(id: id, newName: newName, completion: completion)
    }
    
    func deleteShelf(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.deleteShelf(id: id, completion: completion)
    }
    
    func fetchBooks(completion: @escaping (Result<[Book], Error>) -> Void) {
        coreDataManager.fetchBooks(completion: completion)
    }

    func exportData() -> Data? {
        return coreDataManager.exportData()
    }
    
    func importData(_ data: Data) -> Bool {
        return coreDataManager.importData(data)
    }
    
    func clearAllData(completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.clearAllData(completion: completion)
    }
}
