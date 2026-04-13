import SwiftUI

struct SuccessOverlay: View {
    @Binding var isPresented: Bool

    var body: some View {
        if isPresented {
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                Text("Success")
                    .font(.headline)
            }
            .padding(24)
            .background(.ultraThickMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(radius: 10)
            .transition(.opacity.combined(with: .scale(scale: 0.7, anchor: .center)))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation(.spring(duration: 0.3, bounce: 0.15)) {
                        isPresented = false
                    }
                }
            }
        }
    }
}
