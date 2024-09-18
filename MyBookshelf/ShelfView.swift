import SwiftUI

struct ShelfView: View {
    @State private var shelves: [Shelf] = []
    @State private var newShelfName = ""
    @State private var isLoading = false
    @State private var errorMessage: AlertItem?

    var body: some View {
        VStack {
            Text("Bookshelves")
                .font(.largeTitle)
                .padding()

            if isLoading {
                ProgressView()
            } else {
                List {
                    ForEach(shelves) { shelf in
                        HStack {
                            Text(shelf.name)
                            Spacer()
                            Text("\(shelf.bookCount)+")
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
        .onAppear(perform: loadShelves)
        .alert(item: $errorMessage) { alertItem in
            Alert(title: Text("Error"), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }

    private func loadShelves() {
        isLoading = true
        if CloudKitManager.useSimulatedData {
            // 使用模拟数据
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { // 模拟网络延迟
                shelves = [
                    Shelf(name: "Fiction", bookCount: 5),
                    Shelf(name: "Non-fiction", bookCount: 3),
                    Shelf(name: "Science", bookCount: 2)
                ]
                isLoading = false
            }
        } else {
            CloudKitManager.shared.fetchShelves { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success(let fetchedShelves):
                        shelves = fetchedShelves
                    case .failure(let error):
                        errorMessage = AlertItem(title: "Error", message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private func addShelf() {
        guard !newShelfName.isEmpty else { return }
        let newShelf = Shelf(name: newShelfName, bookCount: 0)
        shelves.append(newShelf)
        if !CloudKitManager.useSimulatedData {
            saveShelves()
        }
        newShelfName = ""
    }

    private func deleteShelf(at offsets: IndexSet) {
        shelves.remove(atOffsets: offsets)
        if !CloudKitManager.useSimulatedData {
            saveShelves()
        }
    }

    private func saveShelves() {
        CloudKitManager.shared.saveShelves(shelves) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    break
                case .failure(let error):
                    errorMessage = AlertItem(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }
}

struct Shelf: Identifiable {
    let id = UUID()
    var name: String
    var bookCount: Int
}
