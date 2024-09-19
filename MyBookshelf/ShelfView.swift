import SwiftUI

struct ShelfView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var storageManager: StorageManager
    @State private var shelves: [Shelf] = []
    @State private var newShelfName = ""
    @State private var isLoading = false
    @State private var alertItem: AlertItem?
    @State private var editingShelfId: UUID?
    @State private var editingShelfName = ""
    
    var body: some View {
        NavigationView {
            List {
                if isLoading {
                    ProgressView()
                } else {
                    ForEach(shelves) { shelf in
                        if editingShelfId == shelf.id {
                            HStack {
                                TextField("Shelf Name", text: $editingShelfName)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                Button(action: {
                                    updateShelf(shelf, newName: editingShelfName)
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                }
                                Button(action: {
                                    editingShelfId = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        } else {
                            HStack {
                                Text(shelf.name)
                                Spacer()
                                Text("\(shelf.bookCount) books")
                            }
                            .onTapGesture(count: 2) {
                                editingShelfId = shelf.id
                                editingShelfName = shelf.name
                            }
                        }
                    }
                    .onDelete(perform: deleteShelf)
                    
                    HStack {
                        TextField("Add Shelf", text: $newShelfName)
                        Button(action: addShelf) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle("Bookshelves")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        isPresented = false
                    }
                }
            }
        }
        .onAppear(perform: loadShelves)
        .alert(item: $alertItem) { item in
            Alert(title: Text(item.title), message: Text(item.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadShelves() {
        isLoading = true
        storageManager.fetchShelves { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedShelves):
                    self.shelves = fetchedShelves
                case .failure(let error):
                    self.alertItem = AlertItem(
                        title: "Error",
                        message: "Failed to load shelves: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func addShelf() {
        guard !newShelfName.isEmpty else { return }
        storageManager.addShelf(name: newShelfName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadShelves()
                    newShelfName = ""
                case .failure(let error):
                    self.alertItem = AlertItem(
                        title: "Error",
                        message: "Failed to add shelf: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func updateShelf(_ shelf: Shelf, newName: String) {
        storageManager.updateShelf(id: shelf.id, newName: newName) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadShelves()
                    self.editingShelfId = nil
                case .failure(let error):
                    self.alertItem = AlertItem(
                        title: "Error",
                        message: "Failed to update shelf: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    private func deleteShelf(at offsets: IndexSet) {
        guard let index = offsets.first, index < shelves.count else { return }
        let shelfToDelete = shelves[index]
        storageManager.deleteShelf(id: shelfToDelete.id) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadShelves()
                case .failure(let error):
                    self.alertItem = AlertItem(
                        title: "Error",
                        message: "Failed to delete shelf: \(error.localizedDescription)"
                    )
                }
            }
        }
    }
}
