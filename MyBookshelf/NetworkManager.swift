import Foundation

class NetworkManager {
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchBookInfo(isbn: String, completion: @escaping (Result<Book, Error>) -> Void) {
        let urlString = "https://isbnsearch.org/isbn/\(isbn)"
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
            
            // 这里需要解析HTML内容，为了简化，我们使用一个假的解析方法
            let book = self.parseHTML(data: data, isbn: isbn)
            completion(.success(book))
        }.resume()
    }
    
    private func parseHTML(data: Data, isbn: String) -> Book {
        // 这里应该实现实际的HTML解析逻辑
        // 为了演示，我们返回一个假的Book对象
        return Book(title: "Sample Book", author: "Sample Author", isbn13: isbn, isbn10: "", publisher: "Sample Publisher", publishDate: "2023", coverImage: nil, isInReadingList: true)
    }
}
