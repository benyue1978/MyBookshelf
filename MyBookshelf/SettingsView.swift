import SwiftUI

struct SettingsView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var storageManager: StorageManager
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var showingClearDataAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Data Management")) {
                    Button("Export Data") {
                        exportData()
                    }
                    
                    Button("Import Data") {
                        showingImportSheet = true
                    }
                    
                    Button("Clear All Data") {
                        showingClearDataAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
            .alert(isPresented: $showingClearDataAlert) {
                Alert(
                    title: Text("Confirm"),
                    message: Text("Are you sure you want to clear all data? This action cannot be undone."),
                    primaryButton: .destructive(Text("Clear")) {
                        clearAllData()
                    },
                    secondaryButton: .cancel()
                )
            }
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportView(storageManager: storageManager)
        }
    }
    
    private func exportData() {
        if let data = storageManager.exportData() {
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("MyBookshelf_export.json")
            do {
                try data.write(to: url)
                showingExportSheet = true
            } catch {
                print("Error exporting data: \(error)")
            }
        }
    }

    private func clearAllData() {
        let storageManager = StorageManager(inMemory: false)  // 使用持久化存储
        storageManager.clearAllData { result in
            switch result {
            case .success:
                print("All data cleared successfully")
            case .failure(let error):
                print("Error clearing data: \(error.localizedDescription)")
            }
        }
    }
}

struct ImportView: UIViewControllerRepresentable {
    let storageManager: StorageManager
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.json], asCopy: true)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let parent: ImportView
        
        init(_ parent: ImportView) {
            self.parent = parent
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            do {
                let data = try Data(contentsOf: url)
                if parent.storageManager.importData(data) {
                    print("Data imported successfully")
                } else {
                    print("Failed to import data")
                }
            } catch {
                print("Error reading file: \(error)")
            }
        }
    }
}
