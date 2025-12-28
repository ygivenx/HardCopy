import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    var onFrameCaptured: (CGImage, AVCaptureVideoPreviewLayer) -> Void

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onFrameCaptured = onFrameCaptured
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}



class CameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    var onFrameCaptured: ((CGImage, AVCaptureVideoPreviewLayer) -> Void)?
    private let ciContext = CIContext()
    private var captureNextFrame = false


    override func viewDidLoad() {
        super.viewDidLoad()
        checkCameraAuthorization()

        NotificationCenter.default.addObserver(self, selector: #selector(captureSingleFrame), name: .triggerScan, object: nil)
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    granted ? self.setupCamera() : self.showPermissionDeniedMessage()
                }
            }
        default:
            showPermissionDeniedMessage()
        }
    }

    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else {
            print("⚠️ Failed to set up camera input.")
            return
        }

        // Configure autofocus
        do {
            try camera.lockForConfiguration()

            // Enable continuous autofocus if available
            if camera.isFocusModeSupported(.continuousAutoFocus) {
                camera.focusMode = .continuousAutoFocus
            } else if camera.isFocusModeSupported(.autoFocus) {
                camera.focusMode = .autoFocus
            }

            // Enable auto exposure
            if camera.isExposureModeSupported(.continuousAutoExposure) {
                camera.exposureMode = .continuousAutoExposure
            }

            // Enable auto white balance
            if camera.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                camera.whiteBalanceMode = .continuousAutoWhiteBalance
            }

            camera.unlockForConfiguration()
        } catch {
            print("⚠️ Failed to configure camera settings: \(error)")
        }

        captureSession.beginConfiguration()
        captureSession.addInput(input)

        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        }

        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        if let device = AVCaptureDevice.default(for: .video) {
            try? device.lockForConfiguration()

            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }

            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }

            device.unlockForConfiguration()
        }

        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    private func showPermissionDeniedMessage() {
        let label = UILabel()
        label.text = "Camera permission denied.\nGo to Settings to enable."
        label.textColor = .systemBackground
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }

    @objc func captureSingleFrame() {
        captureNextFrame = true
    }
}

extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard captureNextFrame else { return }
        captureNextFrame = false

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent),
           let preview = previewLayer {
            // Call the callback directly without dispatching to main thread
            // The callback will handle its own threading
            self.onFrameCaptured?(cgImage, preview)
        }
    }
}
