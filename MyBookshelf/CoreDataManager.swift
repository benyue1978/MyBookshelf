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
    
    func saveShelves(_ shelves: [Shelf], completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext
        
        for shelf in shelves {
            let shelfEntity = ShelfEntity(context: context)
            shelfEntity.name = shelf.name
            shelfEntity.bookCount = Int16(shelf.bookCount)
        }
        
        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
    
    func fetchShelves(completion: @escaping (Result<[Shelf], Error>) -> Void) {
        let context = persistentContainer.viewContext
        let fetchRequest: NSFetchRequest<ShelfEntity> = ShelfEntity.fetchRequest()
        
        do {
            let shelfEntities = try context.fetch(fetchRequest)
            let shelves = shelfEntities.map { entity in
                Shelf(name: entity.name ?? "", bookCount: Int(entity.bookCount))
            }
            completion(.success(shelves))
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
                     isbn: entity.isbn ?? "",
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
}
