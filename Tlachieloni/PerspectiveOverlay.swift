import SwiftUI

struct PerspectiveOverlay: View {
    let image: UIImage
    let opacity: Double
    let frameSize: CGSize

    @Binding var topLeft: CGPoint
    @Binding var topRight: CGPoint
    @Binding var bottomLeft: CGPoint
    @Binding var bottomRight: CGPoint

    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(uiImage: image)
                .resizable()
                .frame(width: frameSize.width, height: frameSize.height)
                .opacity(opacity)
                .modifier(Perspective(
                    size: frameSize,
                    tl: topLeft, tr: topRight,
                    bl: bottomLeft, br: bottomRight
                ))

            handle($topLeft)
            handle($topRight)
            handle($bottomLeft)
            handle($bottomRight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func handle(_ pt: Binding<CGPoint>) -> some View {
        Circle()
            .fill(.white)
            .frame(width: 28, height: 28)
            .overlay(Circle().stroke(.blue, lineWidth: 2))
            .shadow(radius: 3)
            .position(pt.wrappedValue)
            .gesture(DragGesture().onChanged { pt.wrappedValue = $0.location })
    }
}

private struct Perspective: GeometryEffect {
    let size: CGSize
    let tl, tr, bl, br: CGPoint

    var animatableData: EmptyAnimatableData { get { .init() } set {} }

    func effectValue(size _: CGSize) -> ProjectionTransform {
        guard size.width > 0, size.height > 0 else { return .init() }
        let t = perspectiveCATransform(size: size, tl: tl, tr: tr, bl: bl, br: br)
        return ProjectionTransform(t)
    }
}

// Computes a CATransform3D that maps the rect (0,0,w,h) to the quad (tl,tr,br,bl)
private func perspectiveCATransform(size: CGSize, tl: CGPoint, tr: CGPoint, bl: CGPoint, br: CGPoint) -> CATransform3D {
    let w = size.width, h = size.height
    let src: [(Double,Double)] = [(0,0), (Double(w),0), (Double(w),Double(h)), (0,Double(h))]
    let dst: [(Double,Double)] = [(Double(tl.x),Double(tl.y)), (Double(tr.x),Double(tr.y)), (Double(br.x),Double(br.y)), (Double(bl.x),Double(bl.y))]

    let a: [[Double]] = (0..<4).flatMap { i -> [[Double]] in
        let (sx,sy) = src[i]; let (dx,dy) = dst[i]
        return [
            [sx, sy, 1, 0, 0, 0, -sx*dx, -sy*dx],
            [0, 0, 0, sx, sy, 1, -sx*dy, -sy*dy]
        ]
    }
    let b: [Double] = dst.flatMap { [$0.0, $0.1] }

    guard let h = solve8x8(a, b) else { return CATransform3DIdentity }

    var t = CATransform3DIdentity
    t.m11 = h[0]; t.m21 = h[1]; t.m41 = h[2]
    t.m12 = h[3]; t.m22 = h[4]; t.m42 = h[5]
    t.m14 = h[6]; t.m24 = h[7]; t.m44 = 1.0
    return t
}

private func solve8x8(_ a: [[Double]], _ b: [Double]) -> [Double]? {
    let n = 8
    var m = a; var r = b
    for col in 0..<n {
        var pivot = col
        for row in (col+1)..<n where abs(m[row][col]) > abs(m[pivot][col]) { pivot = row }
        m.swapAt(col, pivot); r.swapAt(col, pivot)
        guard abs(m[col][col]) > 1e-10 else { return nil }
        let d = m[col][col]
        for j in col..<n { m[col][j] /= d }; r[col] /= d
        for row in 0..<n where row != col {
            let f = m[row][col]
            for j in col..<n { m[row][j] -= f * m[col][j] }
            r[row] -= f * r[col]
        }
    }
    return r
}
