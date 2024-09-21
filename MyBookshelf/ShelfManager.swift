import Foundation
import Combine

class ShelfManager: ObservableObject {
    @Published var shelves: [Shelf] = []
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
            }
        }
    }
}