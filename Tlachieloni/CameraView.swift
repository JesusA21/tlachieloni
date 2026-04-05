import SwiftUI
import AVFoundation

struct CameraView: UIViewRepresentable {
    @Binding var lensIndex: Int

    func makeUIView(context: Context) -> CameraUIView { CameraUIView() }

    func updateUIView(_ uiView: CameraUIView, context: Context) {
        uiView.switchTo(index: lensIndex)
    }
}

class CameraUIView: UIView {
    let session = AVCaptureSession()
    private lazy var previewLayer = AVCaptureVideoPreviewLayer(session: session)
    private var currentIndex = -1

    lazy var availableCameras: [AVCaptureDevice] = {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video, position: .back
        ).devices
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        session.sessionPreset = .high
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        switchTo(index: 0)
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }
    }

    required init?(coder: NSCoder) { fatalError() }

    func switchTo(index: Int) {
        guard index != currentIndex, index < availableCameras.count else { return }
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        if let input = try? AVCaptureDeviceInput(device: availableCameras[index]),
           session.canAddInput(input) {
            session.addInput(input)
            currentIndex = index
        }
        session.commitConfiguration()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
