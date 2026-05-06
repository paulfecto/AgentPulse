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
    @Published var isLoading = false
    @Published var isLoadingOlderMessages = false
    @Published var hasOlderMessages = false
    @Published var errorMessage: String?

    private let transcriptPageLimit = 40
    private let keychain = KeychainStore()

    private init() {
        session = keychain.loadSession()
    }

    var isPaired: Bool {
        session != nil
    }

    func bootstrapFromLaunchEnvironmentIfNeeded() async {
        #if DEBUG
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
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let nextSummary = try await AgentPulseClient(session: session).summary()
            summary = nextSummary
            persistStableRemoteSession(from: nextSummary)
            if let selectedThread {
                self.selectedThread = summary?.threads.first(where: { $0.threadId == selectedThread.threadId }) ?? selectedThread
                await loadThread(selectedThread.threadId)
            }
        } catch {
            handle(error)
        }
    }

    func loadThread(_ threadId: String) async {
        guard let session else { return }
        errorMessage = nil
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
        do {
            try await AgentPulseClient(session: session).sendReply(threadId: thread.threadId, text: text)
            await loadThread(thread.threadId)
            await refresh()
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

    func registerPushToken(_ token: String) async {
        guard let session else { return }
        do {
            try await AgentPulseClient(session: session).registerPushToken(token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ensurePushRegistration() async {
        await requestPushPermission()
    }

    func signOut() {
        if let session {
            Task {
                try? await AgentPulseClient(session: session).deletePushToken()
            }
        }
        keychain.clearSession()
        session = nil
        summary = nil
        selectedThread = nil
        navigationThread = nil
        transcript = nil
        hasOlderMessages = false
        errorMessage = nil
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
        errorMessage = error.localizedDescription
        if error.localizedDescription.lowercased().contains("revoked") {
            signOut()
        }
    }

    private func persistStableRemoteSession(from summary: WatchSummaryResponse) {
        guard
            let session,
            summary.remoteAccess.enabled,
            summary.remoteAccess.mode == "named" || summary.remoteAccess.mode == "edge",
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
}

private extension String {
    var trimmedNonEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    func trimmedSlash() -> String {
        hasSuffix("/") ? String(dropLast()) : self
    }
}
