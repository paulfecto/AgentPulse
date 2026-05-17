import SwiftUI

@main
struct AgentPulseMobileApp: App {
    var body: some Scene {
        WindowGroup {
            AgentPulseMobileRootView()
        }
    }
}

struct AgentPulseMobileRootView: View {
    var body: some View {
        VStack(spacing: 18) {
            Image("AppIconPreview")
                .resizable()
                .frame(width: 86, height: 86)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(color: Color.black.opacity(0.18), radius: 12, y: 5)

            VStack(spacing: 8) {
                Text("Agent Pulse")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                Text("Install the Watch app from TestFlight, then pair it with https://beta.dope-ai.kr/agent-pulse.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 28)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.07, blue: 0.10),
                    Color(red: 0.02, green: 0.12, blue: 0.16)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
        )
        .foregroundStyle(.white)
    }
}
