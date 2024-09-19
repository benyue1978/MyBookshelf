import Foundation

class Shelf: Identifiable, ObservableObject {
    let id: UUID
    var name: String
    var bookCount: Int
    
    init(id: UUID = UUID(), name: String, bookCount: Int) {
        self.id = id
        self.name = name
        self.bookCount = bookCount
    }
}
