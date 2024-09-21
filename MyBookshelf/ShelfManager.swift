import Foundation
import Combine

class ShelfManager: ObservableObject {
    @Published var shelves: [Shelf] = []
    @Published var dataChanged = false
    
    private var storageManager: StorageManager
    
    init(storageManager: StorageManager) {
        self.storageManager = storageManager
        loadShelves()
    }
    
    func loadShelves() {
        storageManager.fetchShelves { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedShelves):
                    self.shelves = fetchedShelves
                case .failure(let error):
                    print("Failed to fetch shelves: \(error.localizedDescription)")
                }
                self.dataChanged = false
            }
        }
    }
    
    func addShelf(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.addShelf(name: name, completion: completion)
        self.dataChanged = true
        completion(.success(()))
    }
    
    func updateShelf(id: UUID, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.updateShelf(id: id, newName: newName, completion: completion)
        self.dataChanged = true
        completion(.success(()))
    }
    
    func deleteShelf(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.deleteShelf(id: id, completion: completion)
        self.dataChanged = true
        completion(.success(()))
    }
    
    func reinitialize(with storageManager: StorageManager) {
        self.storageManager = storageManager
        self.shelves = []
        self.dataChanged = true
        loadShelves()
    }
}