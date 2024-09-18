import SwiftUI
import AVFoundation

struct ScannerView: UIViewControllerRepresentable {
    @Binding var scannedCode: String
    @Binding var alertItem: AlertItem?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        controller.dismissAction = {
            self.presentationMode.wrappedValue.dismiss()
        }
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        var parent: ScannerView
        
        init(_ parent: ScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
            
            if metadataObject.type == .ean8 || metadataObject.type == .ean13 {
                let scannedCode = metadataObject.stringValue ?? ""
                parent.scannedCode = scannedCode
                DispatchQueue.main.async {
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
}

class ScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var delegate: AVCaptureMetadataOutputObjectsDelegate?
    var dismissAction: (() -> Void)?
    var scannedISBNLabel: UILabel!
    var addButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
        setupBackButton()
        setupScannedISBNLabel()
        setupAddButton()
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if (captureSession.canAddInput(videoInput)) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if (captureSession.canAddOutput(metadataOutput)) {
            captureSession.addOutput(metadataOutput)
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.ean8, .ean13]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    private func setupBackButton() {
        let backButton = UIButton(type: .system)
        backButton.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonTapped), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backButton)
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
    
    private func setupScannedISBNLabel() {
        scannedISBNLabel = UILabel()
        scannedISBNLabel.textAlignment = .center
        scannedISBNLabel.textColor = .white
        scannedISBNLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        scannedISBNLabel.layer.cornerRadius = 8
        scannedISBNLabel.clipsToBounds = true
        scannedISBNLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scannedISBNLabel)
        
        NSLayoutConstraint.activate([
            scannedISBNLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            scannedISBNLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scannedISBNLabel.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            scannedISBNLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    private func setupAddButton() {
        addButton = UIButton(type: .system)
        addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
        addButton.tintColor = .white
        addButton.backgroundColor = UIColor.systemBlue
        addButton.layer.cornerRadius = 30
        addButton.addTarget(self, action: #selector(addButtonTapped), for: .touchUpInside)
        addButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(addButton)
        
        NSLayoutConstraint.activate([
            addButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            addButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 60),
            addButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    @objc private func backButtonTapped() {
        dismissAction?()
    }
    
    @objc private func addButtonTapped() {
        if let scannedISBN = scannedISBNLabel.text, !scannedISBN.isEmpty {
            // 使用扫描到的 ISBN
            dismissAction?()
        } else {
            // 显示手动输入 ISBN 的 alert
            let alert = UIAlertController(title: "Enter ISBN", message: nil, preferredStyle: .alert)
            alert.addTextField { textField in
                textField.placeholder = "ISBN"
                textField.keyboardType = .numberPad
            }
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
                if let isbn = alert.textFields?.first?.text, !isbn.isEmpty {
                    self?.scannedISBNLabel.text = isbn
                    // 使用扫描到的 ISBN
                    self?.updateScannedISBN(isbn)
                    self?.dismissAction?()
                }
            })
            present(alert, animated: true)
        }
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject else { return }
        
        if metadataObject.type == .ean8 || metadataObject.type == .ean13 {
            let scannedCode = metadataObject.stringValue ?? ""
            scannedISBNLabel.text = scannedCode
            delegate?.metadataOutput?(output, didOutput: metadataObjects, from: connection)
        }
    }
    
    func updateScannedISBN(_ isbn: String) {
        scannedISBNLabel.text = isbn
    }
}
