import SwiftUI
import AVFoundation

struct ScannerViewController: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var alertItem: AlertItem?
    @Binding var isCameraActive: Bool
    @Binding var capturedImage: UIImage?
    @Binding var isCapturing: Bool
    @Binding var isResetting: Bool
    var onPhotoCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        let scannerView = CameraScannerView(frame: viewController.view.bounds)
        scannerView.onCodeScanned = { code in
            self.scannedCode = code
        }
        scannerView.onCodeDisappeared = {
            self.scannedCode = ""
        }
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
                            self.onPhotoCapture(image)
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
            if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
                if metadataObject.type == .ean8 || metadataObject.type == .ean13 {
                    DispatchQueue.main.async {
                        self.parent.scannedCode = metadataObject.stringValue ?? ""
                    }
                }
            }
        }
    }
}