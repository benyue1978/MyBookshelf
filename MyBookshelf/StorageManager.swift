import Foundation
import CoreData

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    private let coreDataManager: CoreDataManager
    
    // 将初始化方法改为公开
    init() {
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
        // 这里应该实现实际的保存逻辑，可能是保存到Core Data或其他存储方式
        // 为了演示，我们只是模拟一个成功的保存操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(.success(()))
        }
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
