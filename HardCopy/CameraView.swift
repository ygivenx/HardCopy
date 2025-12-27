import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    var onFrameCaptured: (CGImage) -> Void
    var cropRect: CGRect // 👈 add this (in normalized coordinates)

    func makeUIViewController(context: Context) -> CameraViewController {
        let controller = CameraViewController()
        controller.onFrameCaptured = onFrameCaptured
        controller.normalizedCropRect = cropRect
        return controller
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {
        uiViewController.normalizedCropRect = cropRect
    }
}



class CameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private let videoOutput = AVCaptureVideoDataOutput()
    var onFrameCaptured: ((CGImage) -> Void)?
    private let ciContext = CIContext()
    private var captureNextFrame = false
    var normalizedCropRect: CGRect = CGRect(x: 0, y: 0.25, width: 1, height: 0.5) // Default to center band


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

        captureSession.startRunning()
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
        if let cgImage = ciContext.createCGImage(ciImage, from: ciImage.extent) {
            onFrameCaptured?(cgImage)
        }
    }
}
