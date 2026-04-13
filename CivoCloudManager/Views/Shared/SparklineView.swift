import SwiftUI

struct SparklineView: View {
    let data: [Double]
    var color: Color = .blue
    var height: CGFloat = 30

    var body: some View {
        if data.count < 2 {
            Rectangle()
                .fill(color.opacity(0.1))
                .frame(height: height)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            GeometryReader { geo in
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = max(maxVal - minVal, 0.001)
                let stepX = geo.size.width / CGFloat(data.count - 1)

                ZStack(alignment: .bottom) {
                    // Filled area
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geo.size.height))
                        for (index, value) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height - CGFloat((value - minVal) / range) * geo.size.height
                            if index == 0 {
                                path.addLine(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                        path.addLine(to: CGPoint(x: CGFloat(data.count - 1) * stepX, y: geo.size.height))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    // Line stroke
                    Path { path in
                        for (index, value) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = geo.size.height - CGFloat((value - minVal) / range) * geo.size.height
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                }
            }
            .frame(height: height)
            .clipShape(RoundedRectangle(cornerRadius: 4))
        }
    }
}
