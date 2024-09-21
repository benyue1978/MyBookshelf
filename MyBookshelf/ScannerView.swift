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
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    ScannerViewController(scannedCode: $scannedCode, alertItem: $alertItem, isCameraActive: $isCameraActive, capturedImage: $capturedImage, isCapturing: $isCapturing, isResetting: $isResetting)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack {
                        Spacer()
                        
                        if !scannedCode.isEmpty {
                            Text("Scanned ISBN: \(scannedCode)")
                                .padding()
                                .background(Color.black.opacity(0.7))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        
                        ZStack {
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
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 72, height: 72)
                                    
                                    Image(systemName: capturedImage == nil ? "camera.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.white)
                                }
                            }
                            .position(x: geometry.size.width / 2, y: 0)
                            .disabled(isCapturing || isResetting)
                            
                            // 绿色对钩按钮
                            if capturedImage != nil {
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
            let coverImage = capturedImage?.jpegData(compressionQuality: 0.8)
            let newBook = Book(
                id: UUID(),
                title: "",
                author: "",
                isbn13: scannedCode.count == 13 ? scannedCode : "",
                isbn10: scannedCode.count == 10 ? scannedCode : "",
                publisher: "",
                publishDate: "",
                coverImage: coverImage,
                shelfUuid: nil,
                isInReadingList: false
            )
            
            BookView(book: newBook, isPresented: $showingBookView) {
                showingBookView = false
                isCameraActive = true
                capturedImage = nil
                scannedCode = ""
            }
        }
        .alert(item: $alertItem) { alertItem in
            Alert(title: Text(alertItem.title), message: Text(alertItem.message), dismissButton: .default(Text("OK")))
        }
    }
}

struct ScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var alertItem: AlertItem?
    @Binding var isCameraActive: Bool
    @Binding var capturedImage: UIImage?
    @Binding var isCapturing: Bool
    @Binding var isResetting: Bool
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let scannerView = CameraScannerView(frame: viewController.view.bounds)
        viewController.view.addSubview(scannerView)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let scannerView = uiViewController.view.subviews.first as? CameraScannerView {
            scannerView.isCameraActive = self.isCameraActive
            
            if isCapturing {
                print("Attempting to capture image...")
                scannerView.captureImage { image in
                    DispatchQueue.main.async {
                        self.capturedImage = image
                        self.isCapturing = false
                        self.isCameraActive = false
                        print("Image captured and set: \(image != nil)")
                        if let image = image {
                            print("Captured image size: \(image.size)")
                        }
                    }
                }
            }
            
            if isResetting {
                print("Resetting camera")
                DispatchQueue.main.async {
                    self.capturedImage = nil
                    self.scannedCode = ""
                    self.isCameraActive = true
                    self.isResetting = false
                }
                scannerView.reset()
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: ScannerViewController
        
        init(_ parent: ScannerViewController) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
            
            if metadataObject.type == .ean8 || metadataObject.type == .ean13 {
                DispatchQueue.main.async {
                    self.parent.scannedCode = metadataObject.stringValue ?? ""
                }
            }
        }
    }
}

class CameraScannerView: UIView, AVCapturePhotoCaptureDelegate {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var photoOutput: AVCapturePhotoOutput!
    private var completionHandler: ((UIImage?) -> Void)?
    
    private var isCameraActiveInternal = false
    var isCameraActive: Bool {
        get { isCameraActiveInternal }
        set {
            isCameraActiveInternal = newValue
            updateCameraState()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCaptureSession()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCaptureSession()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
            let videoInput: AVCaptureDeviceInput
            
            do {
                videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            } catch {
                return
            }
            
            if (self.captureSession.canAddInput(videoInput)) {
                self.captureSession.addInput(videoInput)
            } else {
                return
            }
            
            self.photoOutput = AVCapturePhotoOutput()
            if self.captureSession.canAddOutput(self.photoOutput) {
                self.captureSession.addOutput(self.photoOutput)
            }
            
            DispatchQueue.main.async {
                self.previewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
                self.previewLayer.frame = self.bounds
                self.previewLayer.videoGravity = .resizeAspectFill
                self.layer.addSublayer(self.previewLayer)
                
                self.updateCameraState()
            }
        }
    }
    
    private func updateCameraState() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            if self.isCameraActiveInternal {
                if !self.captureSession.isRunning {
                    self.captureSession.startRunning()
                    print("Capture session started")
                }
            } else {
                if self.captureSession.isRunning {
                    self.captureSession.stopRunning()
                    print("Capture session stopped")
                }
            }
        }
    }
    
    func captureImage(completion: @escaping (UIImage?) -> Void) {
        guard captureSession.isRunning else {
            print("Capture session is not running")
            completion(nil)
            return
        }

        self.completionHandler = completion

        let settings = AVCapturePhotoSettings()
        print("Capturing photo...")
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("Error capturing photo: \(error.localizedDescription)")
            completionHandler?(nil)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from captured data")
            completionHandler?(nil)
            return
        }
        
        print("Photo captured successfully")
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(image)
        }
    }

    func reset() {
        isCameraActive = true
    }
}
