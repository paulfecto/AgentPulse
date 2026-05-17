import Foundation
import UserNotifications
import WatchKit

@MainActor
final class AgentPulseStore: ObservableObject {
    static let shared = AgentPulseStore()

    @Published private(set) var session: AgentPulseSession?
    @Published var summary: WatchSummaryResponse?
    @Published var selectedThread: WatchThread?
    @Published var navigationThread: WatchThread?
    @Published var transcript: ThreadTranscript?
    @Published var attention: WatchAttentionResponse?
    @Published var projects: [AgentPulseProject] = []
    @Published var isLoading = false
    @Published var isLoadingOlderMessages = false
    @Published var isLoadingAttention = false
    @Published var isLoadingProjects = false
    @Published var isFollowingRun = false
    @Published var hasOlderMessages = false
    @Published var errorMessage: String?

    private let transcriptPageLimit = 8
    private let runFollowMaxAttempts = 120
    private let runFollowIntervalNanoseconds: UInt64 = 2_000_000_000
    private let keychain = KeychainStore()
    #if DEBUG
    private var simulatorPreviewState: SimulatorPreviewState?
    private var simulatorPreviewOlderMessagesLoaded = false

    var simulatorPreviewScreen: SimulatorPreviewState? {
        simulatorPreviewState
    }

    var isSimulatorPreviewFixture: Bool {
        simulatorPreviewState != nil
    }
    #endif

    private init() {
        session = keychain.loadSession()
    }

    var isPaired: Bool {
        session != nil
    }

    func bootstrapFromLaunchEnvironmentIfNeeded() async {
        #if DEBUG
        if applySimulatorPreviewIfRequested() {
            return
        }

        let environment = ProcessInfo.processInfo.environment
        let forceBootstrap = environment["AGENT_PULSE_BOOTSTRAP_FORCE"] == "1"
        guard session == nil || forceBootstrap else { return }
        guard
            let baseUrl = environment["AGENT_PULSE_BOOTSTRAP_BASE_URL"]?.trimmedNonEmpty,
            let deviceId = environment["AGENT_PULSE_BOOTSTRAP_DEVICE_ID"]?.trimmedNonEmpty,
            let token = environment["AGENT_PULSE_BOOTSTRAP_TOKEN"]?.trimmedNonEmpty,
            let fingerprint = environment["AGENT_PULSE_BOOTSTRAP_FINGERPRINT"]?.trimmedNonEmpty
        else {
            return
        }

        do {
            let nextSession = AgentPulseSession(
                baseUrl: baseUrl,
                deviceId: deviceId,
                token: token,
                fingerprint: fingerprint
            )
            try keychain.saveSession(nextSession)
            session = nextSession
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
        #endif
    }

    func pair(baseUrl: String, pin: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let trimmedBase = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
            let lookup = try await AgentPulseClient.lookup(baseUrl: trimmedBase, pin: pin)
            let fingerprint = keychain.fingerprint()
            let pair = try await AgentPulseClient.pair(baseUrl: lookup.baseUrl, pin: pin, fingerprint: fingerprint)
            let nextSession = AgentPulseSession(
                baseUrl: lookup.baseUrl,
                deviceId: pair.deviceId,
                token: pair.token,
                fingerprint: fingerprint
            )
            try keychain.saveSession(nextSession)
            session = nextSession
            await requestPushPermission()
            await refresh()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refresh() async {
        guard let session else {
            errorMessage = AgentPulseWatchError.missingSession.localizedDescription
            return
        }
        #if DEBUG
        if let simulatorPreviewState {
            summary = makeSimulatorPreviewSummary(state: simulatorPreviewState)
            if simulatorPreviewState == .error {
                errorMessage = "Preview helper unavailable"
            }
            if let selectedThread {
                self.selectedThread = summary?.threads.first(where: { $0.threadId == selectedThread.threadId }) ?? selectedThread
            }
            return
        }
        #endif
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let nextSummary = try await AgentPulseClient(session: session).summary()
            summary = nextSummary
            persistStableRemoteSession(from: nextSummary)
            if nextSummary.capabilities.attentionCount > 0 {
                await loadAttention()
            } else {
                attention = WatchAttentionResponse(items: [], total: 0)
            }
            if let selectedThread {
                self.selectedThread = summary?.threads.first(where: { $0.threadId == selectedThread.threadId }) ?? selectedThread
                await loadThread(selectedThread.threadId)
            }
        } catch {
            handle(error)
        }
    }

    func loadAttention() async {
        guard let session else { return }
        #if DEBUG
        if let simulatorPreviewState {
            attention = makeSimulatorPreviewAttention(state: simulatorPreviewState)
            return
        }
        #endif
        isLoadingAttention = true
        errorMessage = nil
        defer { isLoadingAttention = false }
        do {
            attention = try await AgentPulseClient(session: session).attention()
        } catch {
            handle(error)
        }
    }

    func loadProjects() async {
        guard let session else { return }
        #if DEBUG
        if simulatorPreviewState != nil {
            projects = [AgentPulseProject(
                projectId: "preview-agent-pulse",
                name: "AgentPulse",
                path: "/Volumes/paulfecto/Development_team/AgentPulse",
                providers: ["codex"]
            )]
            return
        }
        #endif
        isLoadingProjects = true
        errorMessage = nil
        defer { isLoadingProjects = false }
        do {
            projects = try await AgentPulseClient(session: session).projects().projects
                .filter { $0.providers.contains("codex") }
        } catch {
            handle(error)
        }
    }

    func loadThread(_ threadId: String) async {
        guard let session else { return }
        errorMessage = nil
        #if DEBUG
        if simulatorPreviewState != nil {
            transcript = makeSimulatorPreviewTranscript(threadId: threadId, includeOlderPage: simulatorPreviewOlderMessagesLoaded)
            hasOlderMessages = !simulatorPreviewOlderMessagesLoaded
            return
        }
        #endif
        do {
            let nextTranscript = try await AgentPulseClient(session: session).transcript(
                threadId: threadId,
                limit: transcriptPageLimit
            )
            transcript = nextTranscript
            hasOlderMessages = nextTranscript.messages.count >= transcriptPageLimit
        } catch {
            handle(error)
        }
    }

    func loadOlderMessagesIfNeeded(currentMessageId: String? = nil) async {
        guard !isLoadingOlderMessages, hasOlderMessages, let session, let currentTranscript = transcript else {
            return
        }
        #if DEBUG
        if simulatorPreviewState != nil {
            if let currentMessageId, currentMessageId != currentTranscript.messages.first?.id {
                return
            }
            simulatorPreviewOlderMessagesLoaded = true
            transcript = makeSimulatorPreviewTranscript(
                threadId: currentTranscript.threadId,
                includeOlderPage: true
            )
            hasOlderMessages = false
            return
        }
        #endif
        guard let oldestMessage = currentTranscript.messages.first else {
            hasOlderMessages = false
            return
        }
        if let currentMessageId, currentMessageId != oldestMessage.id {
            return
        }

        isLoadingOlderMessages = true
        defer { isLoadingOlderMessages = false }
        do {
            let older = try await AgentPulseClient(session: session).olderMessages(
                threadId: currentTranscript.threadId,
                before: oldestMessage.id,
                limit: transcriptPageLimit
            )
            let existingIds = Set(currentTranscript.messages.map(\.id))
            let nextOlderMessages = older.messages.filter { !existingIds.contains($0.id) }
            transcript = ThreadTranscript(
                threadId: currentTranscript.threadId,
                provider: currentTranscript.provider,
                providerThreadId: currentTranscript.providerThreadId,
                activeTurnId: currentTranscript.activeTurnId,
                sendState: currentTranscript.sendState,
                goal: currentTranscript.goal,
                model: currentTranscript.model,
                reasoningEffort: currentTranscript.reasoningEffort,
                permissionMode: currentTranscript.permissionMode,
                fileChanges: currentTranscript.fileChanges,
                messages: nextOlderMessages + currentTranscript.messages
            )
            hasOlderMessages = older.hasMore
        } catch {
            handle(error)
        }
    }

    func select(_ thread: WatchThread) async {
        selectedThread = thread
        transcript = nil
        hasOlderMessages = false
        await loadThread(thread.threadId)
    }

    func sendReply(_ text: String) async {
        guard let session, let thread = selectedThread else { return }
        errorMessage = nil
        #if DEBUG
        if simulatorPreviewState != nil {
            transcript = makeSimulatorPreviewTranscript(threadId: thread.threadId, includeOlderPage: true, replyText: text)
            hasOlderMessages = false
            return
        }
        #endif
        do {
            let response = try await AgentPulseClient(session: session).sendReply(threadId: thread.threadId, text: text)
            transcript = response.transcript
            hasOlderMessages = response.transcript.messages.count >= transcriptPageLimit
            await refresh()
            await followSelectedThreadUntilSettled(threadId: thread.threadId)
        } catch {
            handle(error)
        }
    }

    func startThread(project: AgentPulseProject) async {
        guard let session else { return }
        errorMessage = nil
        do {
            let response = try await AgentPulseClient(session: session).startThread(projectId: project.projectId)
            await refresh()
            selectedThread = response.thread
            navigationThread = response.thread
            await loadThread(response.thread.threadId)
        } catch {
            handle(error)
        }
    }

    func respondToAttention(_ item: WatchAttentionItem, decision: WatchAttentionDecision, answer: String? = nil) async {
        guard let session else { return }
        errorMessage = nil
        do {
            let payload = approvalDecisionPayload(for: item, decision: decision, answer: answer)
            try await AgentPulseClient(session: session).respondToApproval(
                threadId: item.threadId,
                requestId: item.requestId,
                method: item.method,
                decision: payload
            )
            await loadAttention()
            await refresh()
            if selectedThread?.threadId == item.threadId {
                await loadThread(item.threadId)
            }
        } catch {
            handle(error)
        }
    }

    func stopSelectedThread() async {
        guard let session, let thread = selectedThread else { return }
        errorMessage = nil
        do {
            try await AgentPulseClient(session: session).stop(threadId: thread.threadId)
            await refresh()
        } catch {
            handle(error)
        }
    }

    func openSelectedOnMac() async {
        guard let session, let thread = selectedThread else { return }
        errorMessage = nil
        do {
            try await AgentPulseClient(session: session).openOnMac(threadId: thread.threadId)
        } catch {
            handle(error)
        }
    }

    private func approvalDecisionPayload(
        for item: WatchAttentionItem,
        decision: WatchAttentionDecision,
        answer: String?
    ) -> JSONValue {
        if item.method == "item/tool/requestUserInput" || item.method == "tool/requestUserInput" {
            guard decision.id != "skip", let question = item.questions?.first else {
                return .object(["answers": .object([:])])
            }
            let trimmedAnswer = (answer ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            return .object([
                "answers": .object([
                    question.id: .object([
                        "answers": .array([.string(trimmedAnswer)])
                    ])
                ])
            ])
        }

        switch decision.id {
        case "approve_for_session":
            return .string("acceptForSession")
        case "deny":
            return .string("decline")
        case "cancel":
            return .string("cancel")
        default:
            return .string("accept")
        }
    }

    func registerPushToken(_ token: String) async {
        guard let session else { return }
        do {
            try await AgentPulseClient(session: session).registerPushToken(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ensurePushRegistration() async {
        #if DEBUG
        if simulatorPreviewState != nil {
            return
        }
        #endif
        await requestPushPermission()
    }

    func signOut() {
        if let session {
            Task {
                try? await AgentPulseClient(session: session).deletePushToken()
            }
        }
        clearLocalSession()
    }

    private func clearLocalSession(errorMessage nextErrorMessage: String? = nil) {
        keychain.clearSession()
        session = nil
        summary = nil
        selectedThread = nil
        navigationThread = nil
        transcript = nil
        attention = nil
        projects = []
        hasOlderMessages = false
        errorMessage = nextErrorMessage
    }

    private func followSelectedThreadUntilSettled(threadId: String) async {
        guard session != nil else { return }
        guard shouldKeepFollowingSelectedRun(threadId: threadId) else { return }

        isFollowingRun = true
        defer { isFollowingRun = false }

        for _ in 0..<runFollowMaxAttempts {
            do {
                try await Task.sleep(nanoseconds: runFollowIntervalNanoseconds)
            } catch {
                return
            }

            guard selectedThread?.threadId == threadId else { return }
            await refresh()
            guard shouldKeepFollowingSelectedRun(threadId: threadId) else { return }
        }
    }

    private func shouldKeepFollowingSelectedRun(threadId: String) -> Bool {
        guard selectedThread?.threadId == threadId else { return false }

        if transcript?.activeTurnId?.isEmpty == false {
            return true
        }

        switch transcript?.sendState?.reason {
        case "thread_changed", "missing_active_turn", "compacting_context":
            return true
        default:
            break
        }

        switch selectedThread?.status {
        case .running, .compacting:
            return true
        default:
            return false
        }
    }

    func openFromNotification(threadId: String) async {
        await refresh()
        if let thread = summary?.threads.first(where: { $0.threadId == threadId }) {
            navigationThread = thread
            await select(thread)
        }
    }

    private func requestPushPermission() async {
        guard Bundle.main.object(forInfoDictionaryKey: "AgentPulseRemoteNotificationsEnabled") as? Bool == true else {
            return
        }
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            if granted {
                WKExtension.shared().registerForRemoteNotifications()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func handle(_ error: Error) {
        if let watchError = error as? AgentPulseWatchError, watchError.requiresPairingReset {
            clearLocalSession(errorMessage: watchError.localizedDescription)
            return
        }
        errorMessage = error.localizedDescription
        let lowercasedMessage = error.localizedDescription.lowercased()
        if lowercasedMessage.contains("unknown-device") ||
            lowercasedMessage.contains("revoked") ||
            lowercasedMessage.contains("invalid") {
            clearLocalSession(errorMessage: "This Watch is no longer paired with this Agent Pulse server. Pair again with a fresh PIN.")
        }
    }

    private func persistStableRemoteSession(from summary: WatchSummaryResponse) {
        let stableModes = Set(["named", "edge"])
        guard
            let session,
            summary.remoteAccess.enabled,
            stableModes.contains(summary.remoteAccess.mode),
            let remoteUrl = summary.server.remoteUrl?.trimmedNonEmpty,
            remoteUrl.hasPrefix("https://"),
            session.baseUrl.trimmedSlash() != remoteUrl.trimmedSlash()
        else {
            return
        }

        do {
            let nextSession = AgentPulseSession(
                baseUrl: remoteUrl,
                deviceId: session.deviceId,
                token: session.token,
                fingerprint: session.fingerprint
            )
            try keychain.saveSession(nextSession)
            self.session = nextSession
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    #if DEBUG
    @discardableResult
    private func applySimulatorPreviewIfRequested() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        guard environment["AGENT_PULSE_WATCH_PREVIEW_FIXTURE"] == "1" else {
            return false
        }

        let state = SimulatorPreviewState(rawValue: environment["AGENT_PULSE_WATCH_PREVIEW_STATE"] ?? "summary") ?? .summary
        simulatorPreviewState = state
        simulatorPreviewOlderMessagesLoaded = false
        if state == .pairing || state == .revoked {
            session = nil
            summary = nil
            transcript = nil
            selectedThread = nil
            navigationThread = nil
            attention = nil
            projects = []
            hasOlderMessages = false
            errorMessage = state == .revoked ? "Device pairing was revoked. Pair again." : nil
            return true
        }

        errorMessage = state == .error ? "Preview helper unavailable" : nil
        session = AgentPulseSession(
            baseUrl: "https://beta.dope-ai.kr/agent-pulse",
            deviceId: "watch-ultra-preview",
            token: "watch-ultra-preview",
            fingerprint: "watch-ultra-preview"
        )
        summary = makeSimulatorPreviewSummary(state: state)
        transcript = nil
        selectedThread = nil
        navigationThread = nil
        attention = makeSimulatorPreviewAttention(state: state)
        projects = [
            AgentPulseProject(
                projectId: "preview-agent-pulse",
                name: "AgentPulse",
                path: "/Volumes/paulfecto/Development_team/AgentPulse",
                providers: ["codex"]
            )
        ]
        hasOlderMessages = false

        if [.detail, .detailMessages, .detailActions].contains(state), let thread = summary?.threads.first {
            selectedThread = thread
            navigationThread = thread
            transcript = makeSimulatorPreviewTranscript(threadId: thread.threadId, includeOlderPage: state == .detailMessages)
            hasOlderMessages = state == .detail
        }

        return true
    }

    private func makeSimulatorPreviewSummary(state: SimulatorPreviewState) -> WatchSummaryResponse {
        let threads: [WatchThread]
        switch state {
        case .empty:
            threads = []
        default:
            threads = [
                WatchThread(
                    threadId: "preview-main-codex-thread",
                    provider: "codex",
                    title: "Agent Pulse watch deployment",
                    workspace: "AgentPulse",
                    workspaceKind: "repo",
                    status: .running,
                    lastActivityAt: "2026-05-16T11:42:00Z",
                    lastTurnSummary: "Testing public Watch access, full transcript pages, and Codex-safe runtime behavior.",
                    pinned: true,
                    pinnedOrder: 1
                ),
                WatchThread(
                    threadId: "preview-review-thread",
                    provider: "codex",
                    title: "Upstream product sync",
                    workspace: "AgentPulse",
                    workspaceKind: "repo",
                    status: .idle,
                    lastActivityAt: "2026-05-16T10:18:00Z",
                    lastTurnSummary: "Docker gates passed and the beta route remained isolated from Project Manager.",
                    pinned: true,
                    pinnedOrder: 2
                ),
                WatchThread(
                    threadId: "preview-attention-thread",
                    provider: "codex",
                    title: "APNs credential follow-up",
                    workspace: "AgentPulse",
                    workspaceKind: "repo",
                    status: .waitingApproval,
                    lastActivityAt: "2026-05-16T09:33:00Z",
                    lastTurnSummary: "Waiting for the APNs Key ID and private key path before enabling push delivery.",
                    pinned: false,
                    pinnedOrder: nil
                )
            ]
        }

        return WatchSummaryResponse(
            server: WatchSummaryResponse.Server(
                helperName: "Agent Pulse Beta",
                version: "preview",
                baseUrl: "https://beta.dope-ai.kr/agent-pulse",
                remoteUrl: "https://beta.dope-ai.kr/agent-pulse"
            ),
            remoteAccess: WatchSummaryResponse.RemoteAccess(
                enabled: true,
                mode: "edge",
                status: state == .error ? "error" : state == .offline ? "offline" : "healthy",
                publicUrl: "https://beta.dope-ai.kr/agent-pulse",
                hostname: "beta.dope-ai.kr"
            ),
            capabilities: WatchSummaryResponse.Capabilities(
                canOpenOnMac: false,
                openOnMacReason: "Open on Mac is disabled for the Codex-safe beta runtime.",
                canRespond: true,
                canStop: true,
                canApprove: true,
                canAnswerUserInput: true,
                canStartThread: true,
                canReviewArtifacts: true,
                attentionCount: state == .empty ? 0 : 2
            ),
            threads: threads
        )
    }

    private func makeSimulatorPreviewAttention(state: SimulatorPreviewState) -> WatchAttentionResponse {
        guard state != .empty else {
            return WatchAttentionResponse(items: [], total: 0)
        }
        let questionItem = WatchAttentionItem(
            id: "preview-attention-thread:approval-1",
            requestId: "approval-1",
            threadId: "preview-attention-thread",
            provider: "codex",
            threadTitle: "APNs credential follow-up",
            workspace: "AgentPulse",
            method: "item/tool/requestUserInput",
            approvalType: "Question",
            summary: "Which setup should continue?",
            detail: nil,
            riskLevel: "low",
            questions: [
                WatchAttentionQuestion(
                    id: "setup_path",
                    prompt: "Which setup should continue?",
                    options: [
                        WatchAttentionQuestionOption(id: "public", label: "Public route"),
                        WatchAttentionQuestionOption(id: "apns", label: "APNs")
                    ]
                )
            ],
            decisions: [
                WatchAttentionDecision(id: "skip", label: "Skip", style: "destructive")
            ],
            createdAt: "2026-05-16T09:33:00Z"
        )
        let approvalItem = WatchAttentionItem(
            id: "preview-main-codex-thread:approval-2",
            requestId: "approval-2",
            threadId: "preview-main-codex-thread",
            provider: "codex",
            threadTitle: "Agent Pulse watch deployment",
            workspace: "AgentPulse",
            method: "session/requestApproval",
            approvalType: "Command",
            summary: "Run Docker gates and inspect the generated Watch proof screenshots.",
            detail: "The command reads repo files, runs tests, and captures simulator screenshots. It does not touch Codex Desktop.",
            riskLevel: "medium",
            questions: nil,
            decisions: [
                WatchAttentionDecision(id: "approve", label: "Approve", style: "primary"),
                WatchAttentionDecision(id: "approve_for_session", label: "Approve session", style: "primary"),
                WatchAttentionDecision(id: "deny", label: "Deny", style: "destructive")
            ],
            createdAt: "2026-05-16T09:34:00Z"
        )
        let items = state == .attentionDetail || state == .attentionActions
            ? [approvalItem, questionItem]
            : [questionItem, approvalItem]
        return WatchAttentionResponse(items: items, total: items.count)
    }

    private func makeSimulatorPreviewTranscript(
        threadId: String,
        includeOlderPage: Bool = false,
        replyText: String? = nil
    ) -> ThreadTranscript {
        var messages: [ChatMessage] = []
        if includeOlderPage {
            messages.append(contentsOf: [
                ChatMessage(
                    id: "preview-older-1",
                    role: "user",
                    kind: "message",
                    text: "Can this work from cellular and not just my local Wi-Fi?",
                    createdAt: "2026-05-16T08:10:00Z"
                ),
                ChatMessage(
                    id: "preview-older-2",
                    role: "assistant",
                    kind: "message",
                    text: "Yes, but only through the stable beta.dope-ai.kr/agent-pulse route. The Watch should never pair to localhost or a LAN-only address for real world use.",
                    createdAt: "2026-05-16T08:11:00Z"
                )
            ])
        }

        messages.append(contentsOf: [
            ChatMessage(
                id: "preview-message-1",
                role: "user",
                kind: "message",
                text: "I need the Watch to show the same Codex-facing conversation, not subagent rows or summaries.",
                createdAt: "2026-05-16T09:02:00Z"
            ),
            ChatMessage(
                id: "preview-message-2",
                role: "assistant",
                kind: "message",
                text: "The Watch list now follows the Codex-visible thread predicate, keeps pinned title semantics, and loads the full transcript window with older-message pagination.",
                fileReferences: [
                    ThreadFileReference(
                        id: "preview-file-ref-1",
                        label: "ThreadDetailView.swift",
                        displayPath: "apps/watchos/AgentPulseWatch/AgentPulseWatch/ThreadDetailView.swift",
                        kind: "code",
                        language: "swift",
                        messageId: "preview-message-2",
                        turnId: "preview-active-turn",
                        source: "codex"
                    )
                ],
                planItems: [
                    ThreadPlanItem(step: "Expose attention requests", status: "completed"),
                    ThreadPlanItem(step: "Render artifact cards", status: "in_progress"),
                    ThreadPlanItem(step: "Run Docker gates", status: "pending")
                ],
                turnId: "preview-active-turn",
                createdAt: "2026-05-16T09:03:00Z"
            ),
            ChatMessage(
                id: "preview-message-3",
                role: "user",
                kind: "message",
                text: "Make sure Open on Mac is disabled. I do not want this to disturb Codex Desktop.",
                createdAt: "2026-05-16T09:05:00Z"
            ),
            ChatMessage(
                id: "preview-message-4",
                role: "assistant",
                kind: "message",
                text: "Confirmed. The beta helper runs with desktop control disabled, so replies and stops use the spawned Codex app-server transport while /thread/open stays blocked.",
                createdAt: "2026-05-16T09:06:00Z"
            )
        ])

        if let replyText {
            messages.append(
                ChatMessage(
                    id: "preview-reply",
                    role: "user",
                    kind: "message",
                    text: replyText,
                    createdAt: "2026-05-16T09:07:00Z"
                )
            )
        }

        return ThreadTranscript(
            threadId: threadId,
            provider: "codex",
            providerThreadId: threadId,
            activeTurnId: "preview-active-turn",
            sendState: ThreadSendState(
                canSend: true,
                reason: "ready",
                label: "Ready"
            ),
            goal: ThreadGoal(
                objective: "Bring Codex mobile remote-control semantics to AgentPulse Watch.",
                status: "active",
                tokenBudget: nil,
                tokensUsed: 0
            ),
            model: "gpt-5.2",
            reasoningEffort: "high",
            permissionMode: CodexPermissionMode(mode: "default", label: "Default"),
            fileChanges: [
                ThreadFileChangeSummary(
                    id: "preview-file-change-1",
                    threadId: threadId,
                    turnId: "preview-active-turn",
                    itemId: "file-change-preview",
                    fileCount: 2,
                    linesAdded: 148,
                    linesDeleted: 12,
                    files: [
                        ThreadFileChangeFile(
                            path: "apps/helper/src/server/agent-pulse-server.ts",
                            linesAdded: 82,
                            linesDeleted: 6,
                            reference: nil
                        ),
                        ThreadFileChangeFile(
                            path: "apps/watchos/AgentPulseWatch/AgentPulseWatch/ThreadDetailView.swift",
                            linesAdded: 66,
                            linesDeleted: 6,
                            reference: nil
                        )
                    ],
                    action: "undo",
                    canUseCodexApplyPatch: false,
                    unavailableReason: nil
                )
            ],
            messages: messages
        )
    }
    #endif
}

#if DEBUG
enum SimulatorPreviewState: String {
    case pairing
    case summary
    case detail
    case detailMessages
    case detailActions
    case attention
    case attentionDetail
    case attentionActions
    case start
    case empty
    case offline
    case error
    case revoked
}
#endif

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func trimmedSlash() -> String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
