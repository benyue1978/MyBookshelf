//
//  ContentView.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI
import SwiftData
import Combine

struct ContentView: View {
    @EnvironmentObject var shelfManager: ShelfManager
    @EnvironmentObject var bookManager: BookManager
    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var showingShelfListView = false
    @State private var showingScanner = false
    @State private var showingAddBook = false
    @State private var shelfUpdateTrigger = false  // 新增：用于触发更新的状态
    @State private var cancellables = Set<AnyCancellable>()

    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search books", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Reading list
                Text("Reading List")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(bookManager.readingListBooks) { book in
                            BookThumbnail(book: book)
                        }
                    }
                }
                
                // Shelves list
                List(shelfManager.shelves) { shelf in
                    NavigationLink(destination: ShelfDetailView(shelf: shelf)) {
                        HStack {
                            Text(shelf.name)
                            Spacer()
                            Text("\(shelf.bookCount) books")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Navigation buttons
                HStack {
                    Button("Add Book") {
                        showingAddBook = true
                    }
                    Spacer()
                    ScannerButton()
                    Spacer()
                    Button("Shelves") {
                        showingShelfListView = true
                    }
                    Spacer()
                    Button("Settings") {
                        showingSettings = true
                    }
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
                SettingsView(isPresented: $showingSettings, onDataCleared: loadData)
            }
            .fullScreenCover(isPresented: $showingShelfListView) {
                ShelfListView(isPresented: $showingShelfListView, updateTrigger: $shelfUpdateTrigger)
            }
            .onChange(of: shelfUpdateTrigger) { _, _ in
                shelfManager.loadShelves()
            }
            .fullScreenCover(isPresented: $showingAddBook) {
                BookView(book: Book(id: UUID(), title: "", author: "", isbn13: "", isbn10: "", publisher: "", publishDate: "", coverImageURL: nil, shelfUuid: nil, isInReadingList: false), isPresented: $showingAddBook)
            }
        }
        .environmentObject(shelfManager)
        .onAppear {
            setupDataClearedObserver()
            bookManager.loadBooks()
            shelfManager.loadShelves()
        }
    }

    private func setupDataClearedObserver() {
        Publishers.CombineLatest(shelfManager.$dataCleared, bookManager.$dataCleared)
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

struct BookThumbnail: View {
    let book: Book
    
    var body: some View {
        VStack {
            if let coverImageURL = book.coverImageURL, let url = URL(string: coverImageURL) {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fit)
                } placeholder: {
                    Image(systemName: "book.fill")
                }
                .frame(width: 100, height: 150)
            } else {
                Image(systemName: "book.fill")
                    .resizable()
                    .frame(width: 100, height: 150)
            }
            Text(book.title)
                .lineLimit(2)
                .multilineTextAlignment(.center)
        }
        .frame(width: 120)
        .padding()
    }
}

struct ShelfDetailView: View {
    let shelf: Shelf
    
    var body: some View {
        Text("Details for \(shelf.name)")
        Spacer()
        Text("\(shelf.bookCount) books")
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

