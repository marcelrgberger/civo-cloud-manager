import SwiftUI

struct StaggeredAppear: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(x: appeared ? 0 : -8)
            .onAppear {
                appeared = false
                withAnimation(.easeOut(duration: 0.3).delay(Double(index) * 0.04)) {
                    appeared = true
                }
            }
            .onDisappear {
                appeared = false
            }
    }
}
