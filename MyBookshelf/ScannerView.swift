import SwiftUI
import AVFoundation

struct ScannerView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var scannedCode: String = ""
    @State private var alertItem: AlertItem?
    @State private var isCameraActive = true
    @State private var capturedImage: UIImage?
    @State private var showingBookView = false
    
    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                ZStack {
                    ScannerViewController(scannedCode: $scannedCode, alertItem: $alertItem, isCameraActive: $isCameraActive, capturedImage: $capturedImage)
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
                                if isCameraActive {
                                    isCameraActive = false
                                } else {
                                    isCameraActive = true
                                    scannedCode = ""
                                    capturedImage = nil
                                }
                            }) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.black, lineWidth: 2)
                                        .frame(width: 72, height: 72)
                                    
                                    Image(systemName: isCameraActive ? "camera.circle.fill" : "arrow.triangle.2.circlepath.circle.fill")
                                        .resizable()
                                        .frame(width: 70, height: 70)
                                        .foregroundColor(.white)
                                }
                            }
                            .position(x: geometry.size.width / 2, y: 0)
                            
                            // 绿色对钩按钮
                            if !isCameraActive {
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
            BookView(isbn: scannedCode, coverImage: capturedImage, isPresented: $showingBookView)
        }
    }
}

struct ScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var alertItem: AlertItem?
    @Binding var isCameraActive: Bool
    @Binding var capturedImage: UIImage?
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let scannerView = CameraScannerView(frame: viewController.view.bounds)
        scannerView.delegate = context.coordinator
        viewController.view.addSubview(scannerView)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let scannerView = uiViewController.view.subviews.first as? CameraScannerView {
            DispatchQueue.global(qos: .userInitiated).async {
                scannerView.isCameraActive = self.isCameraActive
            }
            if !isCameraActive {
                scannerView.captureImage { image in
                    DispatchQueue.main.async {
                        self.capturedImage = image
                    }
                }
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
            completion(nil)
            return
        }

        self.completionHandler = completion

        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            completionHandler?(nil)
            return
        }
        completionHandler?(image)
    }
}