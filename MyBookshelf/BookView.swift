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
    @State private var showingCamera = false

    var onDismiss: (() -> Void)?

    init(book: Book, isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil) {
        self._book = State(initialValue: book)
        self._isPresented = isPresented
        self.onDismiss = onDismiss
        if let coverImageData = book.coverImage {
            self._coverImage = State(initialValue: UIImage(data: coverImageData))
        }
        // 初始化 selectedShelf
        self._selectedShelf = State(initialValue: book.shelfUuid)
    }

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Book Information")) {
                    CoverImageView(coverImage: book.coverImage != nil ? UIImage(data: book.coverImage!) : nil)
                        .onTapGesture(count: 2) {
                            showingCamera = true
                        }
                    
                    HStack {
                        Text("Title")
                        Spacer()
                        TextField("", text: $book.title)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Title")
                    }
                    HStack {
                        Text("Author")
                        Spacer()
                        TextField("", text: $book.author)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Author")
                    }
                    HStack {
                        Text("Publisher")
                        Spacer()
                        TextField("", text: $book.publisher)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Publisher")
                    }
                    HStack {
                        Text("Publish Date")
                        Spacer()
                        TextField("", text: $book.publishDate)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("Publish Date")
                    }
                    HStack {
                        Text("ISBN-13")
                        Spacer()
                        TextField("", text: $book.isbn13)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("ISBN-13")
                    }
                    HStack {
                        Text("ISBN-10")
                        Spacer()
                        TextField("", text: $book.isbn10)
                            .multilineTextAlignment(.trailing)
                            .accessibilityIdentifier("ISBN-10")
                    }
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
                    .accessibilityIdentifier("ReadingListToggle")
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
            .sheet(isPresented: $showingCamera) {
                CameraView(image: $coverImage, onImageCaptured: { newImage in
                    if let imageData = newImage.jpegData(compressionQuality: 0.8) {
                        book.coverImage = imageData
                        coverImage = newImage
                    }
                })
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

struct CoverImageView: View {
    let coverImage: UIImage?
    
    var body: some View {
        Group {
            if let image = coverImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "book")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.gray)
            }
        }
        .frame(height: 200)
    }
}

