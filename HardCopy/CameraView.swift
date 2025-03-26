import SwiftUI
import AVFoundation

struct CameraView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> CameraViewController {
        return CameraViewController()
    }

    func updateUIViewController(_ uiViewController: CameraViewController, context: Context) {}
}

class CameraViewController: UIViewController {
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()

        checkCameraAuthorization()
    }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.setupCamera()
                    } else {
                        self.showPermissionDeniedMessage()
                    }
                }
            }
        default:
            showPermissionDeniedMessage()
        }
    }

    private func setupCamera() {
        guard let camera = AVCaptureDevice.default(for: .video) else {
            print("⚠️ No camera found.")
            return
        }

        guard let input = try? AVCaptureDeviceInput(device: camera),
              captureSession.canAddInput(input) else {
            print("⚠️ Failed to create or add camera input.")
            return
        }

        captureSession.beginConfiguration()
        captureSession.addInput(input)
        captureSession.commitConfiguration()

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = view.bounds
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()
    }

    private func showPermissionDeniedMessage() {
        let label = UILabel()
        label.text = "Camera permission denied.\nGo to Settings to enable."
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.frame = view.bounds
        view.addSubview(label)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
}
