import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    #if DEBUG
    static var useSimulatedData = true
    #else
    static var useSimulatedData = false
    #endif
    
    private let container: CKContainer
    private let database: CKDatabase
    
    private init() {
        container = CKContainer.default()
        database = container.privateCloudDatabase
    }
    
    func saveShelves(_ shelves: [Shelf], completion: @escaping (Result<Void, Error>) -> Void) {
        let records = shelves.map { shelf -> CKRecord in
            let record = CKRecord(recordType: "Shelf")
            record["name"] = shelf.name
            record["bookCount"] = shelf.bookCount
            return record
        }
        
        let operation = CKModifyRecordsOperation(recordsToSave: records, recordIDsToDelete: nil)
        
        if #available(iOS 15.0, *) {
            operation.modifyRecordsResultBlock = { result in
                switch result {
                case .success:
                    completion(.success(()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            operation.modifyRecordsCompletionBlock = { savedRecords, _, error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
        database.add(operation)
    }
    
    func fetchShelves(completion: @escaping (Result<[Shelf], Error>) -> Void) {
        let query = CKQuery(recordType: "Shelf", predicate: NSPredicate(value: true))
        
        if #available(iOS 15.0, *) {
            database.fetch(withQuery: query, inZoneWith: nil, desiredKeys: nil, resultsLimit: CKQueryOperation.maximumResults) { result in
                switch result {
                case .success(let (matchResults, _)):
                    let shelves = matchResults.compactMap { _, result -> Shelf? in
                        guard case .success(let record) = result,
                              let name = record["name"] as? String,
                              let bookCount = record["bookCount"] as? Int else {
                            return nil
                        }
                        return Shelf(name: name, bookCount: bookCount)
                    }
                    completion(.success(shelves))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } else {
            database.perform(query, inZoneWith: nil) { records, error in
                if let error = error {
                    completion(.failure(error))
                } else if let records = records {
                    let shelves = records.compactMap { record -> Shelf? in
                        guard let name = record["name"] as? String,
                              let bookCount = record["bookCount"] as? Int else {
                            return nil
                        }
                        return Shelf(name: name, bookCount: bookCount)
                    }
                    completion(.success(shelves))
                }
            }
        }
    }
}
