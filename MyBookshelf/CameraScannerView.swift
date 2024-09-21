import UIKit
import AVFoundation

class CameraScannerView: UIView, AVCapturePhotoCaptureDelegate, AVCaptureMetadataOutputObjectsDelegate {
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
    
    var onCodeScanned: ((String) -> Void)?
    var onCodeDisappeared: (() -> Void)?
    private var lastScannedCode: String?
    private var codeDisappearedTimer: Timer?

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
            
            let metadataOutput = AVCaptureMetadataOutput()
            if self.captureSession.canAddOutput(metadataOutput) {
                self.captureSession.addOutput(metadataOutput)
                
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.ean8, .ean13]
            } else {
                return
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
            return
        }
        
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("Failed to create image from captured data")
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.completionHandler?(image)
        }
    }

    func reset() {
        isCameraActive = true
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        if let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject {
            if metadataObject.type == .ean8 || metadataObject.type == .ean13 {
                guard let stringValue = metadataObject.stringValue else { return }
                DispatchQueue.main.async { [weak self] in
                    self?.handleScannedCode(stringValue)
                }
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.startCodeDisappearedTimer()
            }
        }
    }

    private func handleScannedCode(_ code: String) {
        codeDisappearedTimer?.invalidate()
        if code != lastScannedCode {
            lastScannedCode = code
            onCodeScanned?(code)
        }
    }

    private func startCodeDisappearedTimer() {
        codeDisappearedTimer?.invalidate()
        codeDisappearedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            self?.lastScannedCode = nil
            self?.onCodeDisappeared?()
        }
    }
}
