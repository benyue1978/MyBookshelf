import SwiftUI
import Combine

struct ContentView: View {
    @EnvironmentObject var shelfManager: ShelfManager
    @EnvironmentObject var bookManager: BookManager
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var showingShelfListView = false
    @State private var showingScanner = false
    @State private var showingAddBook = false
    @State private var showOnlyReadingList = false
    @State private var cancellables = Set<AnyCancellable>()
    @State private var selectedBook: Book?

    var filteredBooks: [Book] {
        let books = showOnlyReadingList ? bookManager.readingListBooks : bookManager.books
        if searchText.isEmpty {
            return books
        } else {
            return books.filter { $0.title.lowercased().contains(searchText.lowercased()) }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.bottom)
                
                // Main content area
                GeometryReader { geometry in
                    VStack(spacing: 0) {
                        // Books section (2/3 of the available space)
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Books")
                                    .font(.headline)
                                Spacer()
                                Toggle("Reading", isOn: $showOnlyReadingList)
                                    .labelsHidden()
                                Text("In Reading")
                                    .font(.subheadline)
                            }
                            .padding(.horizontal)
                            
                            if filteredBooks.isEmpty {
                                Text("No Books")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List(filteredBooks) { book in
                                    BookRow(book: book)
                                    .onTapGesture {
                                        selectedBook = book
                                    }
                                }
                            }
                        }
                        .frame(height: geometry.size.height * 2/3)
                        
                        Divider().hidden()
                        
                        // Shelves section (1/3 of the available space)
                        VStack(alignment: .leading) {
                            Text("Shelves")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            if shelfManager.shelves.isEmpty {
                                Text("No Shelves")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            } else {
                                List {
                                    ForEach(shelfManager.shelves) { shelf in
                                        NavigationLink(destination: ShelfDetailView(shelf: shelf)) {
                                            HStack {
                                                Text(shelf.name)
                                                Spacer()
                                                Text("\(shelf.bookCount) books")
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                    }
                                }
                                .listStyle(PlainListStyle())
                            }
                        }
                        .frame(height: geometry.size.height * 1/3)
                    }
                }
                
                // Navigation buttons
                HStack {
                    // Button("Add Book") {
                    //     showingAddBook = true
                    // }
                    // Spacer()
                    Button("Scan ISBN") {
                        showingScanner = true
                    }
                    Spacer()
                    Button("Shelves") {
                        showingShelfListView = true
                    }
                    // Spacer()
                    // Button("Settings") {
                    //     showingSettings = true
                    // }
                }
                .padding()
            }
            .navigationTitle("My Bookshelf")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gear")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(isPresented: $showingSettings)
            }
            .fullScreenCover(isPresented: $showingShelfListView) {
                ShelfListView(isPresented: $showingShelfListView)
            }
            .fullScreenCover(isPresented: $showingScanner) {
                ScannerView()
            }
            .fullScreenCover(isPresented: $showingAddBook) {
                BookView(book: Book(id: UUID(), title: "", author: "", isbn13: "", isbn10: "", publisher: "", publishDate: "", coverImage: nil, shelfUuid: nil, isInReadingList: false), isPresented: $showingAddBook)
            }
            .sheet(item: $selectedBook) { book in
                BookView(book: book, isPresented: Binding(
                    get: { selectedBook != nil },
                    set: { if !$0 { selectedBook = nil } }
                ), onDismiss: {
                    selectedBook = nil
                })
            }
        }
        .environmentObject(shelfManager)
        .onAppear {
            setupDataChangedObserver()
            loadData()
        }
    }

    private func setupDataChangedObserver() {
        Publishers.CombineLatest(shelfManager.$dataChanged, bookManager.$dataChanged)
            .filter { $0 || $1 }
            .sink { _ in
                self.loadData()
            }
            .store(in: &cancellables)
    }

    private func loadData() {
        shelfManager.loadShelves()
        bookManager.loadBooks()
    }
}

struct BookRow: View {
    let book: Book
    @EnvironmentObject var shelfManager: ShelfManager
    @State private var showingBookView = false
    
    var body: some View {
        Button(action: {
            showingBookView = true
        }) {
            HStack {
                if let coverImageData = book.coverImage,
                   let coverImage = UIImage(data: coverImageData) {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 60, height: 90)
                } else {
                    Image(systemName: "book")
                        .resizable()
                        .frame(width: 60, height: 90)
                }
                
                VStack(alignment: .leading) {
                    Text(book.title)
                        .font(.headline)
                    if let shelfUuid = book.shelfUuid,
                       let shelf = shelfManager.shelves.first(where: { $0.id == shelfUuid }) {
                        Text("Shelf: \(shelf.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingBookView) {
            BookView(book: book, isPresented: $showingBookView)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let storageManager = StorageManager()
        let shelfManager = ShelfManager(storageManager: storageManager)
        let bookManager = BookManager(storageManager: storageManager)
        
        return ContentView()
            .environmentObject(storageManager)
            .environmentObject(shelfManager)
            .environmentObject(bookManager)
    }
}

