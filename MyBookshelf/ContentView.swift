//
//  ContentView.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @StateObject private var storageManager = StorageManager.shared
    @State private var searchText = ""
    @State private var shelves: [Shelf] = []
    @State private var books: [Book] = []
    @State private var showingSettings = false
    @State private var showingShelfView = false
    @State private var scannedCode = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                TextField("Search Books", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                // Reading list
                Text("Reading List")
                    .font(.headline)
                    .padding(.top)
                
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(books.filter { $0.isInReadingList }) { book in
                            VStack {
                                Image(systemName: "book.fill") // Replace with book cover image
                                    .resizable()
                                    .frame(width: 100, height: 150)
                                Text(book.title)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(width: 120)
                            .padding()
                        }
                    }
                }
                
                // Shelves list
                List(shelves) { shelf in
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
                    Button("Shelf") {
                        showingShelfView = true
                    }
                    Spacer()
                    ScannerButton()
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
                SettingsView(isPresented: $showingSettings)
            }
            .fullScreenCover(isPresented: $showingShelfView) {
                ShelfView(isPresented: $showingShelfView)
            }
        }
        .environmentObject(storageManager)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        storageManager.fetchShelves { result in
            switch result {
            case .success(let fetchedShelves):
                self.shelves = fetchedShelves
            case .failure(let error):
                print("Error fetching shelves: \(error)")
            }
        }
        
        storageManager.fetchBooks { result in
            switch result {
            case .success(let fetchedBooks):
                self.books = fetchedBooks
            case .failure(let error):
                print("Error fetching books: \(error)")
            }
        }
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

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

