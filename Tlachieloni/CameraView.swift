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

    private var currentDevice: AVCaptureDevice? {
        guard currentIndex >= 0, currentIndex < availableCameras.count else { return nil }
        return availableCameras[currentIndex]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        session.sessionPreset = .high
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
        switchTo(index: 0)
        DispatchQueue.global(qos: .userInitiated).async { self.session.startRunning() }

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) { fatalError() }

    func switchTo(index: Int) {
        guard index != currentIndex, index < availableCameras.count else { return }
        session.beginConfiguration()
        session.inputs.forEach { session.removeInput($0) }
        let device = availableCameras[index]
        if let input = try? AVCaptureDeviceInput(device: device),
           session.canAddInput(input) {
            session.addInput(input)
            currentIndex = index
            configureFocus(device)
        }
        session.commitConfiguration()
    }

    private func configureFocus(_ device: AVCaptureDevice) {
        try? device.lockForConfiguration()
        if device.isFocusModeSupported(.continuousAutoFocus) {
            device.focusMode = .continuousAutoFocus
        }
        if device.isExposureModeSupported(.continuousAutoExposure) {
            device.exposureMode = .continuousAutoExposure
        }
        device.unlockForConfiguration()
    }

    @objc private func handleTap(_ r: UITapGestureRecognizer) {
        guard let device = currentDevice else { return }
        let point = previewLayer.captureDevicePointConverted(fromLayerPoint: r.location(in: self))

        try? device.lockForConfiguration()
        if device.isFocusPointOfInterestSupported {
            device.focusPointOfInterest = point
            device.focusMode = .autoFocus
        }
        if device.isExposurePointOfInterestSupported {
            device.exposurePointOfInterest = point
            device.exposureMode = .autoExpose
        }
        device.unlockForConfiguration()

        showFocusIndicator(at: r.location(in: self))
    }

    private func showFocusIndicator(at point: CGPoint) {
        let indicator = UIView(frame: CGRect(x: 0, y: 0, width: 70, height: 70))
        indicator.center = point
        indicator.layer.borderColor = UIColor.yellow.cgColor
        indicator.layer.borderWidth = 1.5
        indicator.alpha = 0
        addSubview(indicator)

        UIView.animate(withDuration: 0.2, animations: {
            indicator.alpha = 1
            indicator.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        }) { _ in
            UIView.animate(withDuration: 0.5, delay: 0.5, animations: {
                indicator.alpha = 0
            }) { _ in
                indicator.removeFromSuperview()
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }
}
