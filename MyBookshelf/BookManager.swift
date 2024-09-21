import Foundation
import Combine

class BookManager: ObservableObject {
    @Published var books: [Book] = []
    @Published var readingListBooks: [Book] = []
    @Published var dataChanged = false
    
    private var storageManager: StorageManager
    
    init(storageManager: StorageManager) {
        self.storageManager = storageManager
        loadBooks()
    }
    
    func loadBooks() {
        storageManager.fetchBooks { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedBooks):
                    self.books = fetchedBooks
                    self.readingListBooks = fetchedBooks.filter { $0.isInReadingList }
                    self.dataChanged = false
                case .failure(let error):
                    print("Failed to fetch books: \(error.localizedDescription)")
                }
                self.dataChanged = false
            }
        }
    }
    
    func addBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.addBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.loadBooks()
                    self.dataChanged = true
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func updateBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.updateBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.loadBooks()
                    self.dataChanged = true
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    func deleteBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.deleteBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    self.loadBooks()
                    self.dataChanged = true
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    func reinitialize(with storageManager: StorageManager) {
        self.storageManager = storageManager
        self.books = []
        self.readingListBooks = []
        self.dataChanged = true
        loadBooks()
    }
}