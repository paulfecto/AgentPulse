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
                        .foregroundColor(.secondary)
                    HStack {
                        StatusDot(status: thread.status.rawValue)
                        Text(thread.status.rawValue.replacingOccurrences(of: "_", with: " "))
                    }
                    .font(.footnote)
                }
            }
            if let transcript = store.transcript {
                MetadataSection(transcript: transcript)
                FileChangesSection(fileChanges: transcript.fileChanges ?? [])
            }
            Section("Messages") {
                if let transcript = store.transcript {
                    if store.isFollowingRun {
                        HStack {
                            ProgressView()
                            Text("Waiting for outcome")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    if store.hasOlderMessages {
                        HStack {
                            Spacer()
                            if store.isLoadingOlderMessages {
                                ProgressView()
                            } else {
                                Text("Load earlier messages")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .onAppear {
                            Task { await store.loadOlderMessagesIfNeeded() }
                        }
                    }
                    ForEach(transcript.messages) { message in
                        MessageRow(message: message)
                            .onAppear {
                                if message.id == transcript.messages.first?.id {
                                    Task {
                                        await store.loadOlderMessagesIfNeeded(currentMessageId: message.id)
                                    }
                                }
                            }
                    }
                    if transcript.messages.isEmpty {
                        HStack {
                            Spacer()
                            WatchLogoMark(size: 34)
                            Spacer()
                        }
                    }
                } else {
                    ProgressView()
                }
            }
            Section("Reply") {
                TextField("Short reply", text: $reply)
                    .lineLimit(4)
                    .onChange(of: reply) { newValue in
                        if newValue.count > 500 {
                            reply = String(newValue.prefix(500))
                        }
                    }
                Text("\(reply.count)/500")
                    .font(.caption2)
                    .foregroundColor(reply.count > 500 ? .red : .secondary)
                Button("Send") {
                    let text = reply.trimmingCharacters(in: .whitespacesAndNewlines)
                    reply = ""
                    Task { await store.sendReply(text) }
                }
                .disabled(reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            Section {
                if store.summary?.capabilities.canOpenOnMac == true {
                    Button("Open on Mac") {
                        Task { await store.openSelectedOnMac() }
                    }
                } else if let reason = store.summary?.capabilities.openOnMacReason {
                    Text(reason)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Button("Stop run") {
                    Task { await store.stopSelectedThread() }
                }
                .foregroundColor(.red)
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
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

#if DEBUG
struct ThreadDetailMessagesPreviewView: View {
    @EnvironmentObject private var store: AgentPulseStore
    let thread: WatchThread

    var body: some View {
        List {
            Section("Messages") {
                if let transcript = store.transcript {
                    ForEach(transcript.messages) { message in
                        MessageRow(message: message)
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle("Messages")
        .task {
            if store.transcript == nil {
                await store.select(thread)
            }
        }
    }
}

struct ThreadDetailActionsPreviewView: View {
    @EnvironmentObject private var store: AgentPulseStore
    let thread: WatchThread

    var body: some View {
        List {
            Section("Actions") {
                if let reason = store.summary?.capabilities.openOnMacReason {
                    Text(reason)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Button("Stop run") {}
                    .foregroundColor(.red)
            }
            Section("Reply") {
                Text("Short reply")
                    .foregroundColor(.secondary)
                Text("Ready to send through Codex app-server")
                    .font(.footnote)
                Text("0/500")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Button("Send") {}
                    .disabled(true)
            }
        }
        .navigationTitle("Thread")
        .task {
            if store.transcript == nil {
                await store.select(thread)
            }
        }
    }
}
#endif

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(message.text ?? "")
                .fixedSize(horizontal: false, vertical: true)
            if let phase = message.phase {
                ArtifactPill(label: phase)
            }
            if let planItems = message.planItems, !planItems.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(planItems.enumerated()), id: \.offset) { _, item in
                        HStack(alignment: .top, spacing: 4) {
                            StatusDot(status: item.status)
                            Text(item.step)
                                .font(.caption2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            if let attachments = message.attachments, !attachments.isEmpty {
                ArtifactGroup(title: "Images") {
                    ForEach(attachments) { attachment in
                        ArtifactPill(label: attachment.alt ?? attachment.kind.capitalized)
                    }
                }
            }
            if let references = message.fileReferences, !references.isEmpty {
                ArtifactGroup(title: "Files") {
                    ForEach(references) { reference in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(reference.label)
                                .font(.caption2)
                            Text(reference.displayPath)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
            }
        }
    }

    private var label: String {
        switch message.role {
        case "activity":
            return message.kind.capitalized
        default:
            return message.role.capitalized
        }
    }
}

private struct MetadataSection: View {
    let transcript: ThreadTranscript

    var body: some View {
        Section("Context") {
            if let sendState = transcript.sendState {
                HStack {
                    StatusDot(status: sendState.canSend ? "idle" : "waiting_approval")
                    Text(sendState.label)
                }
            }
            if let activeTurnId = transcript.activeTurnId, !activeTurnId.isEmpty {
                Label("Active turn", systemImage: "bolt.circle")
                    .font(.caption2)
                Text(activeTurnId)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            if let model = transcript.model {
                MetadataRow(label: "Model", value: model)
            }
            if let reasoningEffort = transcript.reasoningEffort {
                MetadataRow(label: "Reasoning", value: reasoningEffort)
            }
            if let permissionMode = transcript.permissionMode {
                MetadataRow(label: "Permissions", value: permissionMode.label)
            }
            if let goal = transcript.goal {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Goal")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(goal.objective)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(goal.status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

private struct FileChangesSection: View {
    let fileChanges: [ThreadFileChangeSummary]

    var body: some View {
        if !fileChanges.isEmpty {
            Section("File changes") {
                ForEach(fileChanges) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(summary.fileCount) files")
                        Text("+\(summary.linesAdded) -\(summary.linesDeleted)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        ForEach(summary.files, id: \.path) { file in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.path)
                                    .font(.caption2)
                                    .lineLimit(2)
                                Text("+\(file.linesAdded) -\(file.linesDeleted)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        if let reason = summary.unavailableReason {
                            Text(reason)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }
}

private struct MetadataRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.caption2)
        }
    }
}

private struct ArtifactGroup<Content: View>: View {
    let title: String
    let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            content
        }
    }
}

private struct ArtifactPill: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.secondary.opacity(0.15))
            .clipShape(Capsule())
    }
}
