import Foundation
import CoreData

class StorageManager: ObservableObject {
    private let coreDataManager: CoreDataManager
    
    init(inMemory: Bool = false) {
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

    func addBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.addBook(book, completion: completion)
    }

    func updateBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.updateBook(book, completion: completion)
    }

    func deleteBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        coreDataManager.deleteBook(book, completion: completion)
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
