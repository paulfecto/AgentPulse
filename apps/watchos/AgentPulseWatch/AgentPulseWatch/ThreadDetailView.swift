import SwiftUI

struct ThreadDetailView: View {
    @EnvironmentObject private var store: AgentPulseStore
    let thread: WatchThread
    @State private var reply = ""

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(thread.title)
                        .font(.headline)
                    Text(thread.workspace)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    HStack {
                        StatusDot(status: thread.status.rawValue)
                        Text(thread.status.rawValue.replacingOccurrences(of: "_", with: " "))
                    }
                    .font(.footnote)
                }
            }
            Section("Messages") {
                if let transcript = store.transcript {
                    ForEach(transcript.messages.suffix(8)) { message in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(message.role.capitalized)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(message.text ?? "")
                                .lineLimit(5)
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            Section("Reply") {
                TextField("Short reply", text: $reply, axis: .vertical)
                    .lineLimit(1...4)
                    .onChange(of: reply) { _, newValue in
                        if newValue.count > 500 {
                            reply = String(newValue.prefix(500))
                        }
                    }
                Text("\(reply.count)/500")
                    .font(.caption2)
                    .foregroundStyle(reply.count > 500 ? .red : .secondary)
                Button("Send") {
                    let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
                    reply = ""
                    Task { await store.sendReply(text) }
                }
                .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section {
                Button("Open on Mac") {
                    Task { await store.openSelectedOnMac() }
                }
                Button("Stop run", role: .destructive) {
                    Task { await store.stopSelectedThread() }
                }
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundStyle(.red)
            }
        }
        .navigationTitle("Thread")
        .task {
            await store.select(thread)
        }
        .refreshable {
            await store.loadThread(thread.threadId)
        }
    }
}
