import Foundation
import SwiftSoup

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
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.failure(NSError(domain: "Invalid Response", code: 0, userInfo: nil)))
                return
            }
            
            if httpResponse.statusCode == 404 {
                completion(.failure(NSError(domain: "Book Not Found", code: 404, userInfo: nil)))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: 0, userInfo: nil)))
                return
            }
            
            do {
                let book = try self.parseHTML(data: data, isbn: isbn)
                completion(.success(book))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
    
    private func parseHTML(data: Data, isbn: String) throws -> Book {
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "HTML Parsing Error", code: 0, userInfo: nil)
        }
        
        let doc: Document = try SwiftSoup.parse(html)
        
        guard let bookDiv = try doc.select("div#book").first() else {
            throw NSError(domain: "Book information not found", code: 0, userInfo: nil)
        }
        
        // 解析图片
        let imageUrl = try bookDiv.select("div.image img").first()?.attr("src")
        
        // 解析书籍信息
        let bookInfo = try bookDiv.select("div.bookinfo")
        let title = try bookInfo.select("h1").text()
        
        var author = ""
        var isbn10 = ""
        var isbn13 = ""
        var publisher = ""
        var publishDate = ""
        
        let infoElements = try bookInfo.select("p")
        for element in infoElements {
            let text = try element.text()
            if text.starts(with: "Author:") {
                author = text.replacingOccurrences(of: "Author:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.starts(with: "ISBN-10:") {
                isbn10 = text.replacingOccurrences(of: "ISBN-10:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.starts(with: "ISBN-13:") {
                isbn13 = text.replacingOccurrences(of: "ISBN-13:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.starts(with: "Publisher:") {
                publisher = text.replacingOccurrences(of: "Publisher:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            } else if text.starts(with: "Published:") {
                publishDate = text.replacingOccurrences(of: "Published:", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // 获取封面图片数据
        var coverImageData: Data?
        if let imageUrl = imageUrl, let url = URL(string: imageUrl) {
            coverImageData = try? Data(contentsOf: url)
        }
        
        return Book(
            id: UUID(),
            title: title,
            author: author,
            isbn13: isbn13,
            isbn10: isbn10,
            publisher: publisher,
            publishDate: publishDate,
            coverImage: coverImageData
        )
    }
}
