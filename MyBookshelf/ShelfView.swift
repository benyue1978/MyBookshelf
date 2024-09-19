import SwiftUI

struct ShelfView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var storageManager: StorageManager
    @State private var shelves: [Shelf] = []
    @State private var newShelfName = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if isLoading {
                    ProgressView()
                } else {
                    List {
                        ForEach(shelves, id: \.id) { shelf in
                            HStack {
                                Text(shelf.name)
                                Spacer()
                                Text("\(shelf.bookCount)")
                            }
                        }
                        .onDelete(perform: deleteShelf)
                    }
                }
                
                HStack {
                    TextField("Add Shelf", text: $newShelfName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: addShelf) {
                        Text("Add Shelf")
                    }
                }
                .padding()
            }
            .navigationTitle("Bookshelves")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .onAppear(perform: loadShelves)
        .alert(item: Binding<AlertItem?>(
            get: { errorMessage.map { AlertItem(title: "Error", message: $0) } },
            set: { errorMessage = $0?.message }
        )) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func loadShelves() {
        isLoading = true
        storageManager.fetchShelves { result in
            DispatchQueue.main.async {
                isLoading = false
                switch result {
                case .success(let fetchedShelves):
                    shelves = fetchedShelves
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func addShelf() {
        guard !newShelfName.isEmpty else { return }
        let newShelf = Shelf(name: newShelfName, bookCount: 0)
        shelves.append(newShelf)
        saveShelves(newShelves: shelves)
        newShelfName = ""
    }
    
    private func deleteShelf(at offsets: IndexSet) {
        var newShelves = shelves
        newShelves.remove(atOffsets: offsets)
        saveShelves(newShelves: newShelves)
    }
    
    private func saveShelves(newShelves: [Shelf]) {
        storageManager.saveShelves(newShelves) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    loadShelves()  // Reload shelves after saving
                case .failure(let error):
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

struct Shelf: Identifiable, Hashable {
    let id: UUID
    var name: String
    var bookCount: Int
    
    init(id: UUID = UUID(), name: String, bookCount: Int) {
        self.id = id
        self.name = name
        self.bookCount = bookCount
    }
}

struct ShelfView_Previews: PreviewProvider {
    static var previews: some View {
        ShelfView()
            .environmentObject(StorageManager.shared)
    }
}
