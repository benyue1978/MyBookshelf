import SwiftUI

struct BookView: View {
    @EnvironmentObject var bookManager: BookManager
    @EnvironmentObject var shelfManager: ShelfManager
    @Binding var isPresented: Bool
    @Environment(\.presentationMode) var presentationMode
    @State private var book: Book
    @State private var coverImage: UIImage?
    @AppStorage("lastSelectedShelf") private var lastSelectedShelf: String?
    @State private var selectedShelf: UUID?
    @State private var alertItem: AlertItem?
    @State private var isLoading = false

    var onDismiss: (() -> Void)?

    init(book: Book, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self._book = State(initialValue: book)
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        if let coverImageData = book.coverImage {
            self._coverImage = State(initialValue: UIImage(data: coverImageData))
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
                    } else {
                        Image(systemName: "book")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                    }
                    
                    TextField("Title", text: $book.title)
                    TextField("Author", text: $book.author)
                    TextField("Publisher", text: $book.publisher)
                    TextField("Publish Date", text: $book.publishDate)
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
                dismissView()
            }, trailing: Button(action: saveBook) {
                Image(systemName: "checkmark")
            }
            .accessibilityIdentifier("Save")
            )
            .scrollContentBackground(.hidden)
            .onAppear {
                shelfManager.loadShelves()
                loadLastSelectedShelf()
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
        var updatedBook = book
        updatedBook.shelfUuid = selectedShelf
        if let selectedShelf = selectedShelf {
            lastSelectedShelf = selectedShelf.uuidString
        } else {
            lastSelectedShelf = nil
        }
        
        bookManager.saveBook(updatedBook) { result in
            handleSaveResult(result)
        }
        dismissView()
    }

    private func handleSaveResult(_ result: Result<Void, Error>) {
        DispatchQueue.main.async {
            switch result {
            case .success:
                isPresented = false
                onDismiss?()
            case .failure(let error):
                self.alertItem = AlertItem(title: "Error", message: "Failed to save book: \(error.localizedDescription)")
            }
        }
    }

    private func dismissView() {
        isPresented = false
        presentationMode.wrappedValue.dismiss()
        onDismiss?()
    }
}

