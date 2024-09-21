import CoreData

class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    
    private init() {
        persistentContainer = NSPersistentContainer(name: "MyBookshelf")
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
    }
    
    func fetchShelves(completion: @escaping (Result<[Shelf], Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ShelfEntity> = ShelfEntity.fetchRequest()
        
        do {
            let shelfEntities = try context.fetch(fetchRequest)
            let shelves = shelfEntities.compactMap { entity -> Shelf? in
                guard let id = entity.id else { return nil }
                return Shelf(id: id, name: entity.name ?? "", bookCount: Int(entity.bookCount))
            }
            completion(.success(shelves))
        } catch {
            completion(.failure(error))
        }
    }
    
    func addShelf(name: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let newShelf = ShelfEntity(context: context)
        newShelf.id = UUID()
        newShelf.name = name
        newShelf.bookCount = 0
        
        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func updateShelf(id: UUID, newName: String, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ShelfEntity> = ShelfEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let shelfToUpdate = results.first {
                shelfToUpdate.name = newName
                try context.save()
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "com.myapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Shelf not found"])))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteShelf(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ShelfEntity> = ShelfEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let shelfToDelete = results.first {
                context.delete(shelfToDelete)
                try context.save()
                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "com.myapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Shelf not found"])))
            }
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchBooks(completion: @escaping (Result<[Book], Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        
        do {
            let bookEntities = try context.fetch(fetchRequest)
            let books = bookEntities.compactMap { entity -> Book? in
                guard let id = entity.id else { return nil }
                return Book(id:id,
                     title: entity.title ?? "",
                     author: entity.author ?? "",
                     isbn13: entity.isbn13 ?? "",
                     isbn10: entity.isbn10 ?? "",
                     publisher: entity.publisher ?? "",
                     publishDate: entity.publishDate ?? "",
                     coverImage: entity.coverImage ?? nil,
                     shelfUuid: entity.shelfUuid ?? nil,
                     isInReadingList: entity.isInReadingList)
            }
            completion(.success(books))
        } catch {
            completion(.failure(error))
        }
    }
    
    func exportData() -> Data? {
        // 实现数据导出逻辑
        return nil
    }
    
    func importData(_ data: Data) -> Bool {
        // 实现数据导入逻辑
        return false
    }

    func clearAllData(completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let entityNames = ["ShelfEntity", "BookEntity"]
        
        do {
            for entityName in entityNames {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try context.execute(deleteRequest)
            }
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func saveBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        do {
            let existingBooks = try context.fetch(fetchRequest)
            let bookEntity: BookEntity
            let oldShelfUuid = existingBooks.first?.shelfUuid

            if let existingBook = existingBooks.first {
                // 更新现有书籍
                bookEntity = existingBook
            } else {
                // 创建新书籍
                bookEntity = BookEntity(context: context)
                bookEntity.id = book.id
            }
            
            updateBookEntity(bookEntity, with: book)
            
            try context.save()

            // 更新旧的和新的 shelf 的 bookCount
            if let oldShelfUuid = oldShelfUuid {
                updateShelfBookCount(shelfId: oldShelfUuid) { _ in }
            }
            if let newShelfUuid = book.shelfUuid {
                updateShelfBookCount(shelfId: newShelfUuid) { _ in }
            }

            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }

    private func updateBookEntity(_ entity: BookEntity, with book: Book) {
        entity.title = book.title
        entity.author = book.author
        entity.isbn13 = book.isbn13
        entity.isbn10 = book.isbn10
        entity.publisher = book.publisher
        entity.publishDate = book.publishDate
        entity.coverImage = book.coverImage
        entity.shelfUuid = book.shelfUuid
        entity.isInReadingList = book.isInReadingList
    }
    
    func deleteBook(_ book: Book, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", book.id as CVarArg)
        
        do {
            let results = try context.fetch(fetchRequest)
            if let bookToDelete = results.first {
                let shelfUuid = bookToDelete.shelfUuid

                context.delete(bookToDelete)
                try context.save()

                if let shelfUuid = shelfUuid {
                    updateShelfBookCount(shelfId: shelfUuid) { _ in }
                }

                completion(.success(()))
            } else {
                completion(.failure(NSError(domain: "com.myapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Book not found"])))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func updateShelfBookCount(shelfId: UUID, completion: @escaping (Result<Int, Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<BookEntity> = BookEntity.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "shelfUuid == %@", shelfId as CVarArg)
        
        do {
            let bookCount = try context.count(for: fetchRequest)
            
            let shelfFetchRequest: NSFetchRequest<ShelfEntity> = ShelfEntity.fetchRequest()
            shelfFetchRequest.predicate = NSPredicate(format: "id == %@", shelfId as CVarArg)
            
            if let shelfEntity = try context.fetch(shelfFetchRequest).first {
                shelfEntity.bookCount = Int16(bookCount)
                try context.save()
                completion(.success(bookCount))
            } else {
                completion(.failure(NSError(domain: "com.myapp", code: 404, userInfo: [NSLocalizedDescriptionKey: "Shelf not found"])))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
