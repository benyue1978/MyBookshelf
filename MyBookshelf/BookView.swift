import Foundation

struct Book: Identifiable {
    let id = UUID()
    let title: String
    let author: String
    let isbn: String
    var isInReadingList: Bool
}
