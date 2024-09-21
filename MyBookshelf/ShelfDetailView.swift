import SwiftUI

struct ShelfDetailView: View {
    @EnvironmentObject var bookManager: BookManager
    @EnvironmentObject var shelfManager: ShelfManager
    let shelf: Shelf
    @State private var searchText = ""
    @State private var showingAddBook = false
    @State private var alertItem: AlertItem?

    var body: some View {
        VStack {
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            List {
                ForEach(filteredBooks) { book in
                    NavigationLink(destination: BookView(book: book, isPresented: .constant(true))) {
                        BookRow(book: book)
                    }
                }
                .onDelete(perform: deleteBooks)
            }
            .listStyle(PlainListStyle())
        }
        .navigationTitle(shelf.name)
        .navigationBarItems(trailing: Button(action: { showingAddBook = true }) {
            Image(systemName: "plus")
        })
        .sheet(isPresented: $showingAddBook) {
            BookView(book: Book(id: UUID(), title: "", author: "", isbn13: "", isbn10: "", publisher: "", publishDate: "", shelfUuid: shelf.id), isPresented: $showingAddBook)
        }
        .alert(item: $alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
    
    var filteredBooks: [Book] {
        let shelfBooks = bookManager.books.filter { $0.shelfUuid == shelf.id }
        if searchText.isEmpty {
            return shelfBooks
        } else {
            return shelfBooks.filter { book in
                book.title.lowercased().contains(searchText.lowercased()) ||
                book.author.lowercased().contains(searchText.lowercased()) ||
                book.isbn13.contains(searchText) ||
                book.isbn10.contains(searchText)
            }
        }
    }
    
    func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            let book = filteredBooks[index]
            bookManager.deleteBook(book) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // 书籍成功删除，不需要额外操作，因为 bookManager 应该已经更新了 books 数组
                        break
                    case .failure(let error):
                        // 显示错误提示
                        self.alertItem = AlertItem(title: "删除失败", message: error.localizedDescription)
                    }
                }
            }
        }
    }
}
