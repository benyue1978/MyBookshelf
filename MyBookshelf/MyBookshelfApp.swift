//
//  MyBookshelfApp.swift
//  MyBookshelf
//
//  Created by song.yue on 2024/9/18.
//

import SwiftUI

@main
struct MyBookshelfApp: App {
    @StateObject private var storageManager = StorageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
        }
    }
}
