import SwiftUI

struct BookView: View {
    @EnvironmentObject var storageManager: StorageManager
    @Binding var isPresented: Bool
    @State private var book: Book
    @State private var coverImage: UIImage?
    @State private var selectedShelf: UUID?
    @State private var shelves: [Shelf] = []
    @State private var alertItem: AlertItem?
    @State private var isLoading = false

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
                        
                        // 添加调试信息
                        Text("Displaying captured image")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else if let coverImageURL = book.coverImageURL, let url = URL(string: coverImageURL) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fit)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(height: 200)
                        
                        // 添加调试信息
                        Text("Displaying image from URL")
                            .font(.caption)
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "book")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 200)
                        
                        // 添加调试信息
                        Text("No image available")
                            .font(.caption)
                            .foregroundColor(.red)
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
                        Text("On Shelf").tag(UUID?.none)
                        ForEach(shelves) { shelf in
                            Text(shelf.name).tag(shelf.id as UUID?)
                        }
                    }
                }
                
                Toggle("Add to Reading List", isOn: $book.isInReadingList)
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
            .onAppear {
                print("BookView appeared, coverImage: \(coverImage != nil)")
            }
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
        
        loadShelves()
    }
    
    private func loadShelves() {
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
        
        storageManager.addBook(book) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    storageManager.objectWillChange.send()
                    isPresented = false
                case .failure(let error):
                    self.alertItem = AlertItem(title: "Error", message: "Failed to save book: \(error.localizedDescription)")
                }
            }
        }
    }
}

