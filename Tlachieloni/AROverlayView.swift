import SwiftUI
import RealityKit
import ARKit

struct AROverlayView: UIViewRepresentable {
    let image: UIImage
    let opacity: Double

    func makeCoordinator() -> Coordinator { Coordinator(image: image, opacity: opacity) }

    func makeUIView(context: Context) -> ARView {
        let arView = ARView(frame: .zero)

        let config = ARWorldTrackingConfiguration()
        config.planeDetection = [.horizontal, .vertical]
        config.environmentTexturing = .automatic
        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])

        let coaching = ARCoachingOverlayView()
        coaching.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coaching.session = arView.session
        coaching.goal = .anyPlane
        arView.addSubview(coaching)

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        let rotate = UIRotationGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleRotation(_:)))

        // Tap only fires if pan doesn't start
        tap.require(toFail: pan)
        pan.delegate = context.coordinator
        pinch.delegate = context.coordinator
        rotate.delegate = context.coordinator

        arView.addGestureRecognizer(tap)
        arView.addGestureRecognizer(pan)
        arView.addGestureRecognizer(pinch)
        arView.addGestureRecognizer(rotate)

        context.coordinator.arView = arView
        return arView
    }

    func updateUIView(_ uiView: ARView, context: Context) {
        context.coordinator.updateImage(image)
        context.coordinator.updateOpacity(opacity)
    }

    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        weak var arView: ARView?
        private var currentImage: UIImage
        private var currentOpacity: Double
        private var anchorEntity: AnchorEntity?
        private var modelEntity: ModelEntity?
        private var baseScale: SIMD3<Float> = [1, 1, 1]
        private var placed = false

        init(image: UIImage, opacity: Double) {
            self.currentImage = image
            self.currentOpacity = opacity
        }

        func gestureRecognizer(_ g: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }

        // MARK: - Tap: place or reposition

        @objc func handleTap(_ r: UITapGestureRecognizer) {
            guard let arView = arView else { return }
            let loc = r.location(in: arView)

            if let transform = raycast(at: loc) {
                placeImage(at: transform)
            } else if let camera = arView.session.currentFrame?.camera {
                // Fallback: 50cm in front of camera
                var t = matrix_identity_float4x4
                t.columns.3.z = -0.5
                placeImage(at: simd_mul(camera.transform, t))
            }
        }

        // MARK: - Pan: drag to move

        @objc func handlePan(_ r: UIPanGestureRecognizer) {
            guard let arView = arView, let anchor = anchorEntity, placed else { return }
            let loc = r.location(in: arView)

            if let transform = raycast(at: loc) {
                let pos = transform.columns.3
                anchor.position = [pos.x, pos.y, pos.z]
            }
        }

        // MARK: - Pinch: scale

        @objc func handlePinch(_ r: UIPinchGestureRecognizer) {
            guard let model = modelEntity, placed else { return }
            if r.state == .began { baseScale = model.scale }
            model.scale = baseScale * Float(r.scale)
        }

        // MARK: - Rotate

        @objc func handleRotation(_ r: UIRotationGestureRecognizer) {
            guard let model = modelEntity, placed else { return }
            if r.state == .changed {
                // Rotate around the plane's normal (Z in local space since we face camera)
                let angle = Float(-r.rotation)
                model.transform.rotation *= simd_quatf(angle: angle, axis: [0, 0, 1])
                r.rotation = 0
            }
        }

        // MARK: - Raycast helper

        private func raycast(at point: CGPoint) -> simd_float4x4? {
            guard let arView = arView else { return nil }
            let queries: [ARRaycastQuery.Target] = [.existingPlaneGeometry, .existingPlaneInfinite, .estimatedPlane]
            for target in queries {
                if let hit = arView.raycast(from: point, allowing: target, alignment: .any).first {
                    return hit.worldTransform
                }
            }
            return nil
        }

        // MARK: - Place image

        func placeImage(at worldTransform: simd_float4x4) {
            guard let arView = arView else { return }

            if let old = anchorEntity { arView.scene.removeAnchor(old) }

            let anchor = AnchorEntity(world: worldTransform)

            let aspect = currentImage.size.height / max(currentImage.size.width, 1)
            let width: Float = 0.25
            let height = width * Float(aspect)

            let mesh = MeshResource.generatePlane(width: width, height: height)
            let material = buildMaterial()
            let model = ModelEntity(mesh: mesh, materials: [material])

            // Make the image face the camera
            if let camera = arView.session.currentFrame?.camera {
                let camPos = camera.transform.columns.3
                let anchorPos = worldTransform.columns.3
                let dir = SIMD3<Float>(camPos.x - anchorPos.x, 0, camPos.z - anchorPos.z)
                if length(dir) > 0.001 {
                    let forward = normalize(dir)
                    let angle = atan2(forward.x, forward.z)
                    model.transform.rotation = simd_quatf(angle: angle, axis: [0, 1, 0])
                        * simd_quatf(angle: .pi / 2, axis: [1, 0, 0])
                }
            }

            anchor.addChild(model)
            arView.scene.addAnchor(anchor)

            self.anchorEntity = anchor
            self.modelEntity = model
            self.baseScale = model.scale
            self.placed = true
        }

        // MARK: - Updates

        func updateImage(_ image: UIImage) {
            guard image !== currentImage else { return }
            currentImage = image
            rebuildMaterial()
        }

        func updateOpacity(_ opacity: Double) {
            guard opacity != currentOpacity else { return }
            currentOpacity = opacity
            rebuildMaterial()
        }

        private func buildMaterial() -> UnlitMaterial {
            var material = UnlitMaterial()
            if let cgImage = currentImage.cgImage,
               let texture = try? TextureResource.generate(from: cgImage, options: .init(semantic: .color)) {
                material.color = .init(
                    tint: UIColor.white.withAlphaComponent(CGFloat(currentOpacity)),
                    texture: .init(texture)
                )
            }
            material.blending = .transparent(opacity: .init(floatLiteral: Float(currentOpacity)))
            return material
        }

        private func rebuildMaterial() {
            guard let model = modelEntity else { return }
            model.model?.materials = [buildMaterial()]
        }
    }
}
