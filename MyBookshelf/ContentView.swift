//
//  ContentView.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var searchText = ""
    @State private var readingList: [String] = ["Book Name 1", "Book Name 2"] // 示例书名

    var body: some View {
        NavigationView {
            VStack {
                // 搜索框
                TextField("Search Books", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                // 阅读列表
                Text("Reading List")
                    .font(.headline)
                    .padding(.top)

                ScrollView(.horizontal) {
                    HStack {
                        ForEach(readingList, id: \.self) { book in
                            VStack {
                                Image(systemName: "book.fill") // 替换为书籍封面图
                                    .resizable()
                                    .frame(width: 100, height: 150)
                                Text(book)
                            }
                            .padding()
                        }
                    }
                }

                Spacer()

                // 导航按钮
                HStack {
                    NavigationLink(destination: ShelfView()) {
                        Text("Shelf")
                    }
                    Spacer()
                    ScannerButton()
                    Spacer()
                    NavigationLink(destination: SettingsView()) {
                        Text("Settings")
                    }
                }
                .padding()
            }
            .navigationTitle("My Bookshelf")
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

