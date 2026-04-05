import SwiftUI
import AVFoundation

struct ContentView: View {
    @State private var overlayImage: UIImage?
    @State private var showPicker = false
    @State private var opacity: Double = 0.5
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var rotation: Angle = .zero
    @State private var isLocked = false
    @State private var hideControls = false
    @State private var flipH = false
    @State private var flipV = false
    @State private var lensIndex = 0
    @State private var perspectiveMode = false
    @State private var arMode = false
    @State private var pTL = CGPoint.zero
    @State private var pTR = CGPoint.zero
    @State private var pBL = CGPoint.zero
    @State private var pBR = CGPoint.zero

    // Gesture state
    @State private var lastScale: CGFloat = 1.0
    @State private var lastOffset: CGSize = .zero
    @State private var lastRotation: Angle = .zero

    var body: some View {
        ZStack {
            if arMode, let img = overlayImage {
                AROverlayView(image: img, opacity: opacity).ignoresSafeArea()
            } else {
                CameraView(lensIndex: $lensIndex).ignoresSafeArea()

                if let img = overlayImage {
                    if perspectiveMode {
                        GeometryReader { geo in
                            PerspectiveOverlay(
                                image: img, opacity: opacity,
                                frameSize: CGSize(width: 250, height: 250 * (img.size.height / max(img.size.width, 1))),
                                topLeft: $pTL, topRight: $pTR,
                                bottomLeft: $pBL, bottomRight: $pBR
                            )
                            .onAppear { initCorners(in: geo.size, imgSize: img.size) }
                        }
                        .ignoresSafeArea()
                    } else {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250)
                            .opacity(opacity)
                            .scaleEffect(x: flipH ? -scale : scale, y: flipV ? -scale : scale)
                            .rotationEffect(rotation)
                            .offset(offset)
                            .gesture(isLocked ? nil : dragGesture.simultaneously(with: magnifyGesture).simultaneously(with: rotateGesture))
                    }
                }
            }

            // Botón para mostrar/ocultar controles
            VStack {
                HStack {
                    Spacer()
                    Button { lensIndex = (lensIndex + 1) % max(1, cameraCount()) } label: {
                        Text(currentLensLabel())
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .tint(.white)
                    Button { withAnimation { hideControls.toggle() } } label: {
                        Image(systemName: hideControls ? "eye.slash" : "eye")
                            .padding(10)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                    .tint(.white)
                    .padding()
                }
                Spacer()
                if !hideControls { controlBar }
            }
        }
        .sheet(isPresented: $showPicker) {
            ImagePicker(image: $overlayImage)
        }
    }

    private var controlBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Image(systemName: "eye")
                    .foregroundColor(.white)
                Slider(value: $opacity, in: 0...1)
                    .tint(.white)
                    .disabled(isLocked)
                Text("\(Int(opacity * 100))%")
                    .foregroundColor(.white)
                    .frame(width: 44)
            }
            .padding(.horizontal)

            HStack(spacing: 20) {
                Button { showPicker = true } label: {
                    Image(systemName: "photo.on.rectangle")
                }
                .disabled(isLocked)
                Button { resetTransforms() } label: {
                    Image(systemName: "arrow.counterclockwise")
                }
                .disabled(isLocked)
                if overlayImage != nil {
                    Button { isLocked.toggle() } label: {
                        Image(systemName: isLocked ? "lock.fill" : "lock.open")
                    }
                    Button { flipH.toggle() } label: {
                        Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                    }
                    .disabled(isLocked)
                    Button { flipV.toggle() } label: {
                        Image(systemName: "arrow.up.and.down.righttriangle.up.righttriangle.down")
                    }
                    .disabled(isLocked)
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.black.opacity(0.6))

            if overlayImage != nil {
                HStack(spacing: 20) {
                    Button { togglePerspective() } label: {
                        Image(systemName: perspectiveMode ? "rectangle.fill" : "rectangle.and.hand.point.up.left")
                    }
                    .disabled(isLocked || arMode)
                    Button { arMode.toggle(); if arMode { perspectiveMode = false } } label: {
                        Image(systemName: arMode ? "arkit" : "cube.transparent")
                    }
                    .disabled(isLocked)
                    Button { overlayImage = nil } label: {
                        Image(systemName: "xmark.circle")
                    }
                    .disabled(isLocked)
                }
                .buttonStyle(.borderedProminent)
                .tint(.black.opacity(0.6))
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .padding()
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { v in offset = CGSize(width: lastOffset.width + v.translation.width, height: lastOffset.height + v.translation.height) }
            .onEnded { _ in lastOffset = offset }
    }

    private var magnifyGesture: some Gesture {
        MagnifyGesture()
            .onChanged { v in scale = lastScale * v.magnification }
            .onEnded { _ in lastScale = scale }
    }

    private var rotateGesture: some Gesture {
        RotateGesture()
            .onChanged { v in rotation = lastRotation + v.rotation }
            .onEnded { _ in lastRotation = rotation }
    }

    private func resetTransforms() {
        scale = 1.0; lastScale = 1.0
        offset = .zero; lastOffset = .zero
        rotation = .zero; lastRotation = .zero
        opacity = 0.5
        isLocked = false; flipH = false; flipV = false
        perspectiveMode = false; arMode = false
    }

    private func togglePerspective() {
        perspectiveMode.toggle()
    }

    private func initCorners(in screen: CGSize, imgSize: CGSize) {
        let w: CGFloat = 250
        let h = w * (imgSize.height / max(imgSize.width, 1))
        let cx = screen.width / 2, cy = screen.height / 2
        if pTL == .zero && pTR == .zero {
            pTL = CGPoint(x: cx - w/2, y: cy - h/2)
            pTR = CGPoint(x: cx + w/2, y: cy - h/2)
            pBL = CGPoint(x: cx - w/2, y: cy + h/2)
            pBR = CGPoint(x: cx + w/2, y: cy + h/2)
        }
    }

    private var cameras: [AVCaptureDevice] {
        AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInUltraWideCamera, .builtInWideAngleCamera, .builtInTelephotoCamera],
            mediaType: .video, position: .back
        ).devices
    }

    private func cameraCount() -> Int { cameras.count }

    private func currentLensLabel() -> String {
        guard lensIndex < cameras.count else { return "1x" }
        let wide = cameras.first { $0.deviceType == .builtInWideAngleCamera }
        let current = cameras[lensIndex]
        guard let wideFL = wide?.activeFormat.videoFieldOfView, wideFL > 0 else { return "\(lensIndex + 1)x" }
        let ratio = tan(Double(wideFL) * .pi / 360) / tan(Double(current.activeFormat.videoFieldOfView) * .pi / 360)
        let rounded = round(ratio * 10) / 10
        return rounded.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(rounded))x" : String(format: "%.1fx", rounded)
    }
}
