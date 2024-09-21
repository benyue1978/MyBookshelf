import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchBookInfo(isbn: String, completion: @escaping (Result<Book, Error>) -> Void) {
        let urlString = "https://openlibrary.org/api/books?bibkeys=ISBN:\(isbn)&format=json&jscmd=data"
        guard let url = URL(string: urlString) else {
            completion(.failure(NSError(domain: "Invalid URL", code: 0, userInfo: nil)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let bookData = json["ISBN:\(isbn)"] as? [String: Any] {
                    let title = bookData["title"] as? String ?? ""
                    let authors = (bookData["authors"] as? [[String: Any]])?.compactMap { $0["name"] as? String } ?? []
                    let publisher = (bookData["publishers"] as? [[String: Any]])?.first?["name"] as? String ?? ""
                    let publishDate = bookData["publish_date"] as? String ?? ""
                    
                    var coverImage: Data?
                    if let coverURL = (bookData["cover"] as? [String: Any])?["medium"] as? String,
                       let url = URL(string: coverURL) {
                        coverImage = try? Data(contentsOf: url)
                    }
                    
                    let book = Book(id: UUID(),
                                    title: title,
                                    author: authors.joined(separator: ", "),
                                    isbn13: isbn,
                                    isbn10: "",
                                    publisher: publisher,
                                    publishDate: publishDate,
                                    coverImage: coverImage)
                    
                    completion(.success(book))
                } else {
                    completion(.failure(NSError(domain: "Invalid data format", code: 0, userInfo: nil)))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseHTML(data: Data, isbn: String) -> Book {
        // 这里应该实现实际的HTML解析逻辑
        // 为了演示，我们返回一个假的Book对象
        return Book(title: "Sample Book", author: "Sample Author", isbn13: isbn, isbn10: "", publisher: "Sample Publisher", publishDate: "2023", coverImage: nil, isInReadingList: true)
    }
}
