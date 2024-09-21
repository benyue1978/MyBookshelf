import SwiftUI

struct BookView: View {
    @EnvironmentObject var bookManager: BookManager
    @EnvironmentObject var shelfManager: ShelfManager
    @Binding var isPresented: Bool
    @State private var book: Book
    @State private var coverImage: UIImage?
    @AppStorage("lastSelectedShelf") private var lastSelectedShelf: String?
    @State private var selectedShelf: UUID?
    @State private var alertItem: AlertItem?
    @State private var isLoading = false

    init(book: Book, coverImage: UIImage? = nil, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._book = State(initialValue: book)
        self._coverImage = State(initialValue: coverImage)
        
        print("BookView initialized with book: \(book.title)")
        print("Cover image received: \(coverImage != nil)")
        if let image = coverImage {
            print("Received image size: \(image.size)")
        }
    }

    init(isbn: String, coverImage: UIImage?, isPresented: Binding<Bool>) {
        self._isPresented = isPresented
        self._book = State(initialValue: Book(id: UUID(), title: "", author: "", isbn13: isbn.count == 13 ? isbn : "", isbn10: isbn.count == 10 ? isbn : "", publisher: "", publishDate: "", coverImageURL: nil, shelfUuid: nil, isInReadingList: false))
        self._coverImage = State(initialValue: coverImage)
        
        print("BookView initialized with ISBN: \(isbn)")
        print("Cover image received: \(coverImage != nil)")
        if let image = coverImage {
            print("Received image size: \(image.size)")
        }
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
                
                Section(header: Text("ON Shelf")) {
                    Picker("Select Shelf", selection: $selectedShelf) {
                        Text("No Shelf").tag(UUID?.none)
                        ForEach(shelfManager.shelves) { shelf in
                            Text(shelf.name).tag(shelf.id as UUID?)
                        }
                    }
                    .accessibilityIdentifier("ShelfPicker")
                }
                
                Toggle("Add to Reading List", isOn: $book.isInReadingList)
            }
            .navigationTitle("Book Details")
            .navigationBarItems(leading: Button("Cancel") {
                isPresented = false
            }, trailing: Button(action: saveBook) {
                Image(systemName: "checkmark")
            }
            .accessibilityIdentifier("Save")
            )
            .scrollContentBackground(.hidden)
            .onAppear {
                shelfManager.loadShelves()
                loadLastSelectedShelf()
                print("BookView appeared, coverImage: \(coverImage != nil)")
            }
        }
    }

    private func loadLastSelectedShelf() {
        if book.shelfUuid == nil {
            if let lastShelfId = lastSelectedShelf, let uuid = UUID(uuidString: lastShelfId) {
                selectedShelf = uuid
            } else {
                selectedShelf = nil
            }
        } else {
            selectedShelf = book.shelfUuid
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
    }
    
    private func saveBook() {
        book.shelfUuid = selectedShelf
        if let selectedShelf = selectedShelf {
            lastSelectedShelf = selectedShelf.uuidString
        } else {
            lastSelectedShelf = nil
        }
        
        if let coverImage = coverImage, let imageData = coverImage.jpegData(compressionQuality: 0.8) {
            if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                let fileName = "\(book.id).jpg"
                let fileURL = documentsDirectory.appendingPathComponent(fileName)
                do {
                    try imageData.write(to: fileURL)
                    book.coverImageURL = fileURL.path
                } catch {
                    print("Error saving image: \(error)")
                }
            }
        }
        
        bookManager.addBook(book) { result in
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

