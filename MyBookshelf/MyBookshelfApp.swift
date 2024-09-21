//
//  MyBookshelfApp.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI

@main
struct MyBookshelfApp: App {
    @StateObject private var shelfManager: ShelfManager
    @StateObject private var bookManager: BookManager
    
    init() {
        let storageManager: StorageManager
        if CommandLine.arguments.contains("--uitesting") {
            // 使用内存存储的 Core Data 堆栈
            storageManager = StorageManager(inMemory: true)
        } else {
            storageManager = StorageManager()
        }
        
        _shelfManager = StateObject(wrappedValue: ShelfManager(storageManager: storageManager))
        _bookManager = StateObject(wrappedValue: BookManager(storageManager: storageManager))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(shelfManager)
                .environmentObject(bookManager)
        }
    }
}
