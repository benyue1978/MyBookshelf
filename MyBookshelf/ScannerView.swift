import SwiftUI
import AVFoundation

struct ScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var storageManager: StorageManager
    @State private var scannedCode: String = ""
    @State private var alertItem: AlertItem?
    @State private var isCameraActive = true
    @State private var capturedImage: UIImage?
    @State private var showingBookView = false
    @State private var isCapturing = false
    @State private var isResetting = false
    @State private var fetchedBook: Book?
    @State private var isFetchingBookInfo = false
    @State private var fetchError: String?
    @State private var isSearchingISBN = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    ScannerViewController(
                        scannedCode: $scannedCode,
                        alertItem: $alertItem,
                        isCameraActive: $isCameraActive,
                        capturedImage: $capturedImage,
                        isCapturing: $isCapturing,
                        isResetting: $isResetting,
                        onPhotoCapture: handlePhotoCapture
                    )
                    .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        // Scanned ISBN 文本
                        if !scannedCode.isEmpty {
                            Text("Scanned ISBN: \(scannedCode)")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .position(x: geometry.size.width / 2, y: geometry.safeAreaInsets.top + 40)
                        }

                        Spacer()
                        
                        ZStack {
                            // 绿色对钩按钮
                            if fetchedBook != nil || (capturedImage != nil && scannedCode.isEmpty) {
                                Button(action: {
                                    showingBookView = true
                                }) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .resizable()
                                        .frame(width: 50, height: 50)
                                        .foregroundColor(.green)
                                }
                                .position(x: geometry.size.width / 4, y: 0)
                            } 
                                                        
                            // 拍照按钮
                            Button(action: {
                                if capturedImage == nil {
                                    if !isCapturing {
                                        isCapturing = true
                                        print("Camera button pressed: Capturing image")
                                    }
                                } else {
                                    print("Reset button pressed")
                                    isResetting = true
                                    fetchedBook = nil
                                    fetchError = nil
                                    scannedCode = ""
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(width: 72, height: 72)
                                    
                                    Image(systemName: capturedImage == nil ? "camera.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.white)
                                }
                            }
                            .disabled(isCapturing || isResetting || isFetchingBookInfo)
                            .position(x: geometry.size.width / 2, y: 0)
                                                        
                            // 缩略图或提示
                            Group {
                                if isFetchingBookInfo {
                                    ProgressView()
                                        .frame(width: 80, height: 80)
                                } else if let fetchedBook = fetchedBook, let coverImageData = fetchedBook.coverImage, let uiImage = UIImage(data: coverImageData) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(10)
                                } else if let capturedImage = capturedImage {
                                    Image(uiImage: capturedImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 80, height: 80)
                                        .cornerRadius(10)
                                } else if let fetchError = fetchError {
                                    Text(fetchError)
                                        .font(.caption)
                                        .frame(width: 80, height: 80)
                                        .background(Color.gray.opacity(0.3))
                                        .cornerRadius(10)
                                } else {
                                    Color.clear
                                        .frame(width: 80, height: 80)
                                }
                            }
                            .position(x: geometry.size.width * 3 / 4, y: 0)
                        }
                        .frame(height: 32)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitle("Scan ISBN", displayMode: .inline)
            .navigationBarItems(leading: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
        .sheet(isPresented: $showingBookView) {
            if let fetchedBook = fetchedBook {
                BookView(book: fetchedBook, isPresented: $showingBookView) {
                    resetScannerState()
                }
            } else if let capturedImage = capturedImage {
                let newBook = Book(
                    id: UUID(),
                    title: "",
                    author: "",
                    isbn13: scannedCode,
                    isbn10: "",
                    publisher: "",
                    publishDate: "",
                    coverImage: capturedImage.jpegData(compressionQuality: 0.8)
                )
                BookView(book: newBook, isPresented: $showingBookView) {
                    resetScannerState()
                }
            }
        }
    }
    
    private func resetScannerState() {
        showingBookView = false
        isCameraActive = true
        capturedImage = nil
        scannedCode = ""
        fetchedBook = nil
        fetchError = nil
    }
    
    private func loadBookInfo() {
        guard !scannedCode.isEmpty else { return }
        
        isFetchingBookInfo = true
        fetchError = nil
        
        NetworkManager.shared.fetchBookInfo(isbn: scannedCode) { result in
            DispatchQueue.main.async {
                isFetchingBookInfo = false
                switch result {
                case .success(let book):
                    self.fetchedBook = book
                case .failure(_):
                    self.fetchedBook = Book(
                        id: UUID(),
                        title: "",
                        author: "",
                        isbn13: self.scannedCode,
                        isbn10: "",
                        publisher: "",
                        publishDate: "",
                        coverImage: self.capturedImage?.jpegData(compressionQuality: 0.8)
                    )
                    self.fetchError = "Not found online"
                }
            }
        }
    }
    
    private func handlePhotoCapture(image: UIImage) {
        self.capturedImage = image
        if scannedCode.isEmpty {
            // 如果没有识别到 ISBN，直接显示绿色对钩
            self.fetchedBook = Book(
                id: UUID(),
                title: "",
                author: "",
                isbn13: "",
                isbn10: "",
                publisher: "",
                publishDate: "",
                coverImage: image.jpegData(compressionQuality: 0.8)
            )
        } else {
            // 如果识别到 ISBN，开始搜索
            loadBookInfo()
        }
    }
}