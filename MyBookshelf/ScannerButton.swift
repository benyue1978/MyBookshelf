import SwiftUI

struct ScannerButton: View {
    @State private var isPresentingScanner = false
    @State private var scannedCode = ""
    @State private var alertItem: AlertItem?
    
    var body: some View {
        Button(action: {
            isPresentingScanner = true
        }) {
            Text("Scan")
        }
        .fullScreenCover(isPresented: $isPresentingScanner) {
            ScannerView(scannedCode: $scannedCode, alertItem: $alertItem)
        }
        .modifier(ScannedCodeChangeModifier(scannedCode: scannedCode, action: handleScannedISBN))
        .alert(item: $alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
    
    private func handleScannedISBN(_ isbn: String) {
        print("Scanned ISBN: \(isbn)")
        alertItem = AlertItem(title: "Scanned ISBN", message: isbn)
    }
}

struct ScannedCodeChangeModifier: ViewModifier {
    let scannedCode: String
    let action: (String) -> Void
    
    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: scannedCode) { _, newValue in
                if !newValue.isEmpty {
                    action(newValue)
                }
            }
        } else {
            content.onChange(of: scannedCode) { newValue in
                if !newValue.isEmpty {
                    action(newValue)
                }
            }
        }
    }
}
