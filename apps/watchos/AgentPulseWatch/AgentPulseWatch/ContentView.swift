import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AgentPulseStore

    var body: some View {
        NavigationStack {
            Group {
                if store.isPaired {
                    SummaryView()
                } else {
                    PairingView()
                }
            }
            .navigationDestination(item: $store.selectedThread) { thread in
                ThreadDetailView(thread: thread)
            }
        }
        .task {
            if store.isPaired {
                await store.refresh()
            }
        }
    }
}

struct PairingView: View {
    @EnvironmentObject private var store: AgentPulseStore
    @State private var baseUrl = ""
    @State private var pin = ""

    var body: some View {
        Form {
            Section("Helper") {
                TextField("https://helper-url", text: $baseUrl)
                    .textInputAutocapitalization(.never)
                TextField("PIN", text: $pin)
                    .keyboardType(.numberPad)
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
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
            if let summary = store.summary {
                Section(summary.server.helperName) {
                    HStack {
                        StatusDot(status: summary.remoteAccess.status)
                        Text(summary.remoteAccess.enabled ? summary.remoteAccess.status : "local")
                    }
                    Text("v\(summary.server.version)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Section("Threads") {
                    ForEach(summary.threads) { thread in
                        Button {
                            Task { await store.select(thread) }
                        } label: {
                            ThreadRow(thread: thread)
                        }
                    }
                }
            } else if store.isLoading {
                ProgressView()
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }
            Button("Refresh") {
                Task { await store.refresh() }
            }
            Button("Unpair", role: .destructive) {
                store.signOut()
            }
        }
        .navigationTitle("Agent Pulse")
        .refreshable {
            await store.refresh()
        }
    }
}

struct ThreadRow: View {
    let thread: WatchThread

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                StatusDot(status: thread.status.rawValue)
                Text(thread.title)
                    .lineLimit(2)
            }
            Text(thread.lastTurnSummary.isEmpty ? thread.workspace : thread.lastTurnSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
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
