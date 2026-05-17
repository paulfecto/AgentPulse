import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: AgentPulseStore

    var body: some View {
        NavigationView {
            rootView
        }
        .task {
            await store.bootstrapFromLaunchEnvironmentIfNeeded()
            if store.isPaired {
                await store.ensurePushRegistration()
                await store.refresh()
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        #if DEBUG
        if let screen = store.simulatorPreviewScreen {
            simulatorPreviewRoot(for: screen)
        } else {
            liveRoot
        }
        #else
        liveRoot
        #endif
    }

    @ViewBuilder
    private var liveRoot: some View {
        if store.isPaired {
            SummaryView()
        } else {
            PairingView()
        }
    }

    #if DEBUG
    @ViewBuilder
    private func simulatorPreviewRoot(for screen: SimulatorPreviewState) -> some View {
        switch screen {
        case .pairing, .revoked:
            PairingView()
        case .detail:
            if let thread = store.selectedThread ?? store.summary?.threads.first {
                ThreadDetailView(thread: thread)
            } else {
                SummaryView()
            }
        case .detailMessages:
            if let thread = store.selectedThread ?? store.summary?.threads.first {
                ThreadDetailMessagesPreviewView(thread: thread)
            } else {
                SummaryView()
            }
        case .detailActions:
            if let thread = store.selectedThread ?? store.summary?.threads.first {
                ThreadDetailActionsPreviewView(thread: thread)
            } else {
                SummaryView()
            }
        case .attention:
            AttentionView()
        case .attentionDetail:
            if let item = store.attention?.items.first {
                AttentionDetailView(item: item)
            } else {
                AttentionView()
            }
        case .attentionActions:
            if let item = store.attention?.items.first {
                AttentionActionsPreviewView(item: item)
            } else {
                AttentionView()
            }
        case .start:
            StartThreadView()
        case .summary, .empty, .offline, .error:
            SummaryView()
        }
    }
    #endif
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
                if summary.capabilities.attentionCount > 0 {
                    Section("Attention") {
                        NavigationLink(destination: AttentionView()) {
                            HStack {
                                StatusDot(status: "waiting_approval")
                                Text("\(summary.capabilities.attentionCount) pending")
                            }
                        }
                    }
                }
                if summary.capabilities.canStartThread {
                    Section {
                        NavigationLink(destination: StartThreadView()) {
                            Label("New thread", systemImage: "plus.circle")
                        }
                    }
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

struct AttentionView: View {
    @EnvironmentObject private var store: AgentPulseStore

    var body: some View {
        List {
            if store.isLoadingAttention {
                ProgressView()
            }
            ForEach(store.attention?.items ?? []) { item in
                NavigationLink(destination: AttentionDetailView(item: item)) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            StatusDot(status: item.riskLevel == "high" ? "error" : "waiting_approval")
                            Text(item.approvalType)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text(item.threadTitle)
                            .lineLimit(2)
                        Text(item.summary)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .lineLimit(3)
                    }
                }
            }
            if (store.attention?.items ?? []).isEmpty && !store.isLoadingAttention {
                HStack {
                    Spacer()
                    WatchLogoMark(size: 34)
                    Spacer()
                }
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Attention")
        .task {
            await store.loadAttention()
        }
        .refreshable {
            await store.loadAttention()
        }
    }
}

struct AttentionDetailView: View {
    @EnvironmentObject private var store: AgentPulseStore
    let item: WatchAttentionItem
    @State private var answer = ""
    @State private var confirmation: WatchAttentionDecision?

    var body: some View {
        List {
            Section(item.approvalType) {
                Text(item.threadTitle)
                    .font(.headline)
                Text(item.summary)
                if let detail = item.detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                Text(item.riskLevel)
                    .font(.caption2)
                    .foregroundColor(item.riskLevel == "high" ? .red : .secondary)
            }
            if let question = item.questions?.first {
                Section("Answer") {
                    Text(question.prompt)
                    if let options = question.options, !options.isEmpty {
                        ForEach(options) { option in
                            Button(option.label) {
                                answer = option.label
                                confirmation = answerDecision
                            }
                        }
                    } else {
                        TextField("Answer", text: $answer)
                    }
                }
            }
            Section("Actions") {
                ForEach(item.decisions) { decision in
                    Button(decision.label) {
                        confirmation = decision
                    }
                    .foregroundColor(decision.style == "destructive" ? .red : nil)
                }
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("Review")
        .confirmationDialog(
            confirmation?.label ?? "Confirm",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { if !$0 { confirmation = nil } }
            )
        ) {
            if let selectedDecision = confirmation {
                Button(selectedDecision.label, role: selectedDecision.style == "destructive" ? .destructive : nil) {
                    let decision = selectedDecision
                    self.confirmation = nil
                    Task { await store.respondToAttention(item, decision: decision, answer: answer) }
                }
                Button("Cancel", role: .cancel) {
                    self.confirmation = nil
                }
            }
        }
    }

    private var answerDecision: WatchAttentionDecision {
        if let decision = item.decisions.first(where: { $0.id == "approve" }) {
            return decision
        }
        return WatchAttentionDecision(id: "approve", label: "Answer", style: "primary")
    }
}

#if DEBUG
struct AttentionActionsPreviewView: View {
    let item: WatchAttentionItem

    var body: some View {
        List {
            Section("Actions") {
                ForEach(item.decisions) { decision in
                    Text(decision.label)
                        .foregroundColor(decision.style == "destructive" ? .red : nil)
                }
            }
            Section("Confirmation") {
                Text("Every Watch approval requires explicit confirmation before it is sent to Codex app-server.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Review")
    }
}
#endif

struct StartThreadView: View {
    @EnvironmentObject private var store: AgentPulseStore
    @State private var confirmation: AgentPulseProject?

    var body: some View {
        List {
            if store.isLoadingProjects {
                ProgressView()
            }
            ForEach(store.projects) { project in
                Button {
                    confirmation = project
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(project.name)
                        Text(project.path)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            if store.projects.isEmpty && !store.isLoadingProjects {
                Text("No Codex projects")
                    .foregroundColor(.secondary)
            }
            if let error = store.errorMessage {
                Text(error)
                    .foregroundColor(.red)
            }
        }
        .navigationTitle("New")
        .task {
            await store.loadProjects()
        }
        .refreshable {
            await store.loadProjects()
        }
        .confirmationDialog(
            "Start Codex thread",
            isPresented: Binding(
                get: { confirmation != nil },
                set: { if !$0 { confirmation = nil } }
            )
        ) {
            if let selectedProject = confirmation {
                Button("Start in \(selectedProject.name)") {
                    let project = selectedProject
                    self.confirmation = nil
                    Task { await store.startThread(project: project) }
                }
                Button("Cancel", role: .cancel) {
                    self.confirmation = nil
                }
            }
        }
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
