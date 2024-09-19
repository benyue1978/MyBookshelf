import SwiftUI

struct BookView: View {
    @Binding var isPresented: Bool
    @State private var book: Book
    @State private var coverImage: UIImage?
    @EnvironmentObject var storageManager: StorageManager
    @State private var selectedShelf: UUID?
    @State private var shelves: [Shelf] = []
    @State private var alertItem: AlertItem?
    @State private var isLoading = false
    
    init(isbn: String, coverImage: UIImage?, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._book = State(initialValue: Book(title: "", author: "", isbn13: isbn.count == 13 ? isbn : "", isbn10: isbn.count == 10 ? isbn : "", publisher: "", publishDate: "", coverImageURL: nil))
        self._coverImage = State(initialValue: coverImage)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    if let coverImage = coverImage {
                        Image(uiImage: coverImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    } else if let coverImageURL = book.coverImageURL, let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                    } else {
                        Image(systemName: "book")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    }
                    
                    TextField("Title", text: $book.title)
                    TextField("Author", text: $book.author)
                    TextField("Publisher", text: $book.publisher)
                    TextField("Published", text: $book.publishDate)
                    TextField("ISBN-13", text: $book.isbn13)
                    TextField("ISBN-10", text: $book.isbn10)
                }
                
                Section(header: Text("Shelf")) {
                    Picker("Shelf", selection: $selectedShelf) {
                        Text("On Shelf").tag(String?.none)
                        ForEach(shelves) { shelf in
                            Text(shelf.name).tag(Optional(shelf.name))
                        }
                    }
                }
            }
            .navigationTitle("Book Details")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button(action: saveBook) {
                Image(systemName: "checkmark")
            })
            .onAppear(perform: loadBookInfo)
            .alert(item: $alertItem) { item in
                Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
            }
            .overlay(Group {
                if isLoading {
                    ProgressView()
                }
            })
        }
    }
    
    private func loadBookInfo() {
        guard !book.isbn13.isEmpty || !book.isbn10.isEmpty else { return }
        
        isLoading = true
        NetworkManager.shared.fetchBookInfo(isbn: book.isbn13.isEmpty ? book.isbn10 : book.isbn13) { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedBook):
                    self.book = fetchedBook
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Error", message: "Failed to fetch book info: \(error.localizedDescription)")
                }
            }
        }
        
        storageManager.fetchShelves { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let fetchedShelves):
                    self.shelves = fetchedShelves
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Error", message: "Failed to fetch shelves: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveBook() {
        book.shelfUuid = selectedShelf
        storageManager.addBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    isPresented = false
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Error", message: "Failed to save book: \(error.localizedDescription)")
                }
            }
        }
    }
}

