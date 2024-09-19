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
            let books = bookEntities.map { entity in
                Book(title: entity.title ?? "",
                     author: entity.author ?? "",
                     isbn13: entity.isbn13 ?? "",
                     isbn10: entity.isbn10 ?? "",
                     publisher: entity.publisher ?? "",
                     publishDate: entity.publishDate ?? "",
                     coverImageURL: entity.coverImageURL ?? "",
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
        let entityNames = ["ShelfEntity", "BookEntity"] // 添加所有你的实体名称
        
        for entityName in entityNames {
            let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: entityName)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            
            do {
                try context.execute(deleteRequest)
            } catch {
                completion(.failure(error))
                return
            }
        }
        
        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
