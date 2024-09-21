//
//  MyBookshelfApp.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI

@main
struct MyBookshelfApp: App {
    @StateObject private var storageManager = StorageManager()
    @StateObject private var shelfManager: ShelfManager
    
    init() {
        let storage = StorageManager()
        _shelfManager = StateObject(wrappedValue: ShelfManager(storageManager: storage))
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
                .environmentObject(shelfManager)
        }
    }
}
