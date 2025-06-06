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
    
    func saveBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        storageManager.saveBook(book) { result in
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

    func findBook(byISBN isbn: String) -> Book? {
        return books.first { $0.isbn13 == isbn || $0.isbn10 == isbn }
    }
}