import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AgentPulseStore

    var body: some View {
        NavigationView {
            Group {
                if store.isPaired {
                    SummaryView()
                } else {
                    PairingView()
                }
            }
        }
        .task {
            await store.bootstrapFromLaunchEnvironmentIfNeeded()
            if store.isPaired {
                await store.ensurePushRegistration()
                await store.refresh()
            }
        }
    }
}

struct PairingView: View {
    @EnvironmentObject private var store: AgentPulseStore
    @State private var baseUrl = "https://beta.dope-ai.kr/agent-pulse"
    @State private var pin = ""

    var body: some View {
        Form {
            Section {
                HStack {
                    Spacer()
                    WatchLogoMark(size: 54)
                    Spacer()
                }
            }
            Section("Helper") {
                TextField("https://helper-url", text: $baseUrl)
                    .textInputAutocapitalization(.never)
                TextField("PIN", text: $pin)
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Button {
                Task { await store.pair(baseUrl: baseUrl, pin: pin) }
            } label: {
                if store.isLoading {
                    ProgressView()
                } else {
                    Text("Pair")
                }
            }
            .disabled(baseUrl.isEmpty || pin.count < 4 || store.isLoading)
        }
        .navigationTitle("Agent Pulse")
    }
}

struct SummaryView: View {
    @EnvironmentObject private var store: AgentPulseStore

    var body: some View {
        List {
            if let navigationThread = store.navigationThread {
                NavigationLink(
                    destination: ThreadDetailView(thread: navigationThread),
                    isActive: notificationThreadIsActive
                ) {
                    EmptyView()
                }
                .hidden()
            }
            if let summary = store.summary {
                Section(summary.server.helperName) {
                    HStack {
                        WatchLogoMark(size: 24)
                        StatusDot(status: summary.remoteAccess.status)
                        Text(summary.remoteAccess.enabled ? summary.remoteAccess.status : "local")
                    }
                    Text("v\(summary.server.version)")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Section("Threads") {
                    if summary.threads.isEmpty {
                        HStack {
                            Spacer()
                            WatchLogoMark(size: 34)
                            Spacer()
                        }
                    } else {
                        ForEach(summary.threads) { thread in
                            NavigationLink(destination: ThreadDetailView(thread: thread)) {
                                ThreadRow(thread: thread)
                            }
                        }
                    }
                }
            } else if store.isLoading {
                ProgressView()
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
            Button("Refresh") {
                Task { await store.refresh() }
            }
            Button("Unpair") {
                store.signOut()
            }
            .foregroundColor(.red)
        }
        .navigationTitle("Agent Pulse")
        .refreshable {
            await store.refresh()
        }
    }

    private var notificationThreadIsActive: Binding<Bool> {
        Binding(
            get: { store.navigationThread != nil },
            set: { isActive in
                if !isActive {
                    store.navigationThread = nil
                    store.selectedThread = nil
                    store.transcript = nil
                }
            }
        )
    }
}

struct WatchLogoMark: View {
    let size: CGFloat

    var body: some View {
        Image("AgentPulseLogo")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .accessibilityHidden(true)
    }
}

struct ThreadRow: View {
    let thread: WatchThread

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                StatusDot(status: thread.status.rawValue)
                if thread.pinned == true {
                    Image(systemName: "pin.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .accessibilityLabel("Pinned")
                }
                Text(thread.title)
                    .lineLimit(2)
            }
            Text(thread.lastTurnSummary.isEmpty ? thread.workspace : thread.lastTurnSummary)
                .font(.footnote)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct StatusDot: View {
    let status: String

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
    }

    private var color: Color {
        switch status {
        case "error":
            return .red
        case "waiting_approval":
            return .orange
        case "running", "compacting", "starting":
            return .blue
        case "healthy", "idle":
            return .green
        default:
            return .gray
        }
    }
}
