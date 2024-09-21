import Foundation

struct Book: Identifiable, Codable {
    let id: UUID
    var title: String
    var author: String
    var isbn13: String
    var isbn10: String
    var publisher: String
    var publishDate: String
    var coverImage: Data?  // 新增
    var shelfUuid: UUID?
    var isInReadingList: Bool
    
    init(id: UUID = UUID(), title: String, author: String, isbn13: String, isbn10: String, publisher: String, publishDate: String, coverImage: Data? = nil, shelfUuid: UUID? = nil, isInReadingList: Bool = false) {
        self.id = id
        self.title = title
        self.author = author
        self.isbn13 = isbn13
        self.isbn10 = isbn10
        self.publisher = publisher
        self.publishDate = publishDate
        self.coverImage = coverImage
        self.shelfUuid = shelfUuid
        self.isInReadingList = isInReadingList
    }
    
    enum CodingKeys: String, CodingKey {
        case title, author, isbn13, isbn10, publisher, publishDate, coverImage, shelfUuid, isInReadingList
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = UUID()
        title = try container.decode(String.self, forKey: .title)
        author = try container.decode(String.self, forKey: .author)
        isbn13 = try container.decode(String.self, forKey: .isbn13)
        isbn10 = try container.decode(String.self, forKey: .isbn10)
        publisher = try container.decode(String.self, forKey: .publisher)
        publishDate = try container.decode(String.self, forKey: .publishDate)
        coverImage = try container.decodeIfPresent(Data.self, forKey: .coverImage)
        shelfUuid = try container.decodeIfPresent(UUID.self, forKey: .shelfUuid)
        isInReadingList = try container.decode(Bool.self, forKey: .isInReadingList)
    }
}