import Foundation
import CoreData

class StorageManager: ObservableObject {
    static let shared = StorageManager()
    
    private let coreDataManager: CoreDataManager
    
    #if DEBUG
    static var useSimulatedData = true
    #else
    static var useSimulatedData = false
    #endif
    
    private init() {
        self.coreDataManager = CoreDataManager.shared
    }
    
    func saveShelves(_ shelves: [Shelf], completion: @escaping (Result<Void, Error>) -> Void) {
        if StorageManager.useSimulatedData {
            // 使用模拟数据
            completion(.success(()))
        } else {
            coreDataManager.saveShelves(shelves, completion: completion)
        }
    }
    
    func fetchShelves(completion: @escaping (Result<[Shelf], Error>) -> Void) {
        if StorageManager.useSimulatedData {
            // 返回模拟数据
            let simulatedShelves = [
                Shelf(name: "Fiction", bookCount: 5),
                Shelf(name: "Non-fiction", bookCount: 3),
                Shelf(name: "Science", bookCount: 2)
            ]
            completion(.success(simulatedShelves))
        } else {
            coreDataManager.fetchShelves(completion: completion)
        }
    }
    
    func fetchBooks(completion: @escaping (Result<[Book], Error>) -> Void) {
        if StorageManager.useSimulatedData {
            // 返回模拟数据
            let simulatedBooks = [
                Book(title: "1984", author: "George Orwell", isbn: "9780451524935", isInReadingList: true),
                Book(title: "To Kill a Mockingbird", author: "Harper Lee", isbn: "9780446310789", isInReadingList: false),
                Book(title: "The Great Gatsby", author: "F. Scott Fitzgerald", isbn: "9780743273565", isInReadingList: true)
            ]
            completion(.success(simulatedBooks))
        } else {
            coreDataManager.fetchBooks(completion: completion)
        }
    }
    
    func exportData() -> Data? {
        return coreDataManager.exportData()
    }
    
    func importData(_ data: Data) -> Bool {
        return coreDataManager.importData(data)
    }
}
