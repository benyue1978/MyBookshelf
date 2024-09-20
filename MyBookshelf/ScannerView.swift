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
                                .position(x: geometry.size.width / 4 - 25, y: 0)
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
            if let capturedImage = capturedImage {
                BookView(isbn: scannedCode, coverImage: capturedImage, isPresented: $showingBookView)
                    .environmentObject(storageManager)
            } else {
                BookView(isbn: scannedCode, coverImage: nil, isPresented: $showingBookView)
                    .environmentObject(storageManager)
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
        scannerView.delegate = context.coordinator
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
                self.capturedImage = nil
                self.scannedCode = ""
                self.isCameraActive = true
                scannerView.startCaptureSession()
                self.isResetting = false
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

class CameraScannerView: UIView, AVCaptureMetadataOutputObjectsDelegate, AVCapturePhotoCaptureDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var photoOutput: AVCapturePhotoOutput!
    var completionHandler: ((UIImage?) -> Void)?
    
    var isCameraActive: Bool = true {
        didSet {
            if isCameraActive != oldValue {
                DispatchQueue.global(qos: .userInitiated).async {
                    if self.isCameraActive {
                        self.captureSession.startRunning()
                    } else {
                        self.captureSession.stopRunning()
                    }
                }
            }
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
        
        DispatchQueue.global(qos: .userInitiated).async {
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
            
            let metadataOutput = AVCaptureMetadataOutput()
            
            if (self.captureSession.canAddOutput(metadataOutput)) {
                self.captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13]
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
                
                self.captureSession.startRunning()
            }
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        delegate?.metadataOutput?(output, didOutput: metadataObjects, from: connection)
    }
    
    func captureImage(completion: @escaping (UIImage?) -> Void) {
        guard let photoOutput = self.photoOutput else {
            print("photoOutput is nil")
            completion(nil)
            return
        }

        guard captureSession.isRunning else {
            print("Capture session is not running")
            completion(nil)
            return
        }

        let settings = AVCapturePhotoSettings()
        print("Capturing photo with settings: \(settings)")
        photoOutput.capturePhoto(with: settings, delegate: self)
        self.completionHandler = completion
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
        
        print("Photo captured successfully. Image size: \(image.size)")
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(image)
        }
    }

    func startCaptureSession() {
        if !captureSession.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }
}