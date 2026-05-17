import Foundation

enum WatchStatus: String, Codable {
    case idle
    case running
    case compacting
    case waitingApproval = "waiting_approval"
    case error
    case connection
    case unknown
}

struct PairLookupResponse: Decodable {
    let baseUrl: String
    let helperName: String?
}

struct PairResponse: Codable {
    let token: String
    let deviceId: String
    let deviceName: String
}

struct AgentPulseSession: Codable, Equatable {
    var baseUrl: String
    var deviceId: String
    var token: String
    var fingerprint: String
}

struct WatchSummaryResponse: Decodable {
    struct Server: Decodable {
        let helperName: String
        let version: String
        let baseUrl: String
        let remoteUrl: String?
    }

    struct RemoteAccess: Decodable {
        let enabled: Bool
        let mode: String
        let status: String
        let publicUrl: String
        let hostname: String
    }

    struct Capabilities: Decodable {
        let canOpenOnMac: Bool
        let openOnMacReason: String?
        let canRespond: Bool
        let canStop: Bool
        let canApprove: Bool
        let canAnswerUserInput: Bool
        let canStartThread: Bool
        let canReviewArtifacts: Bool
        let attentionCount: Int
    }

    let server: Server
    let remoteAccess: RemoteAccess
    let capabilities: Capabilities
    let threads: [WatchThread]
}

struct WatchThread: Identifiable, Decodable, Hashable {
    let threadId: String
    let provider: String
    let title: String
    let workspace: String
    let workspaceKind: String?
    let status: WatchStatus
    let lastActivityAt: String
    let lastTurnSummary: String
    let pinned: Bool?
    let pinnedOrder: Int?

    var id: String { threadId }
}

struct ThreadTranscript: Decodable {
    let threadId: String
    let provider: String?
    let providerThreadId: String?
    let activeTurnId: String?
    let sendState: ThreadSendState?
    let goal: ThreadGoal?
    let model: String?
    let reasoningEffort: String?
    let permissionMode: CodexPermissionMode?
    let fileChanges: [ThreadFileChangeSummary]?
    let messages: [ChatMessage]

    init(
        threadId: String,
        provider: String? = nil,
        providerThreadId: String? = nil,
        activeTurnId: String? = nil,
        sendState: ThreadSendState? = nil,
        goal: ThreadGoal? = nil,
        model: String? = nil,
        reasoningEffort: String? = nil,
        permissionMode: CodexPermissionMode? = nil,
        fileChanges: [ThreadFileChangeSummary]? = nil,
        messages: [ChatMessage]
    ) {
        self.threadId = threadId
        self.provider = provider
        self.providerThreadId = providerThreadId
        self.activeTurnId = activeTurnId
        self.sendState = sendState
        self.goal = goal
        self.model = model
        self.reasoningEffort = reasoningEffort
        self.permissionMode = permissionMode
        self.fileChanges = fileChanges
        self.messages = messages
    }
}

struct ThreadSendState: Decodable {
    let canSend: Bool
    let reason: String
    let label: String
}

struct ThreadMessageResponse: Decodable {
    let ok: Bool
    let mode: String
    let turnId: String?
    let transcript: ThreadTranscript
}

struct OlderThreadMessagesResponse: Decodable {
    let threadId: String
    let messages: [ChatMessage]
    let hasMore: Bool
}

struct ChatMessage: Identifiable, Decodable {
    let id: String
    let role: String
    let kind: String
    let text: String?
    let attachments: [ChatAttachment]?
    let fileReferences: [ThreadFileReference]?
    let phase: String?
    let planItems: [ThreadPlanItem]?
    let turnId: String?
    let createdAt: String

    init(
        id: String,
        role: String,
        kind: String,
        text: String?,
        attachments: [ChatAttachment]? = nil,
        fileReferences: [ThreadFileReference]? = nil,
        phase: String? = nil,
        planItems: [ThreadPlanItem]? = nil,
        turnId: String? = nil,
        createdAt: String
    ) {
        self.id = id
        self.role = role
        self.kind = kind
        self.text = text
        self.attachments = attachments
        self.fileReferences = fileReferences
        self.phase = phase
        self.planItems = planItems
        self.turnId = turnId
        self.createdAt = createdAt
    }
}

struct ChatAttachment: Identifiable, Decodable {
    let id: String
    let kind: String
    let url: String
    let alt: String?
    let mimeType: String?
}

struct ThreadFileReference: Identifiable, Decodable {
    let id: String
    let label: String
    let displayPath: String
    let kind: String
    let language: String?
    let messageId: String?
    let turnId: String?
    let source: String
}

struct ThreadPlanItem: Decodable {
    let step: String
    let status: String
}

struct ThreadGoal: Decodable {
    let objective: String
    let status: String
    let tokenBudget: Int?
    let tokensUsed: Int?
}

struct CodexPermissionMode: Decodable {
    let mode: String
    let label: String
}

struct ThreadFileChangeSummary: Identifiable, Decodable {
    let id: String
    let threadId: String
    let turnId: String?
    let itemId: String?
    let fileCount: Int
    let linesAdded: Int
    let linesDeleted: Int
    let files: [ThreadFileChangeFile]
    let action: String?
    let canUseCodexApplyPatch: Bool?
    let unavailableReason: String?
}

struct ThreadFileChangeFile: Decodable {
    let path: String
    let linesAdded: Int
    let linesDeleted: Int
    let reference: ThreadFileReference?
}

struct WatchAttentionResponse: Decodable {
    let items: [WatchAttentionItem]
    let total: Int
}

struct WatchAttentionItem: Identifiable, Decodable, Hashable {
    let id: String
    let requestId: String
    let threadId: String
    let provider: String
    let threadTitle: String
    let workspace: String
    let method: String
    let approvalType: String
    let summary: String
    let detail: String?
    let riskLevel: String
    let questions: [WatchAttentionQuestion]?
    let decisions: [WatchAttentionDecision]
    let createdAt: String
}

struct WatchAttentionQuestion: Identifiable, Decodable, Hashable {
    let id: String
    let prompt: String
    let options: [WatchAttentionQuestionOption]?
}

struct WatchAttentionQuestionOption: Identifiable, Decodable, Hashable {
    let id: String
    let label: String
}

struct WatchAttentionDecision: Identifiable, Decodable, Hashable {
    let id: String
    let label: String
    let style: String
}

struct ProjectListResponse: Decodable {
    let projects: [AgentPulseProject]
}

struct AgentPulseProject: Identifiable, Decodable, Hashable {
    let projectId: String
    let name: String
    let path: String
    let providers: [String]

    var id: String { projectId }
}

struct ThreadCreateResponse: Decodable {
    let thread: WatchThread
}

struct WatchPushRequest: Encodable {
    let pushToken: String
    let bundleId: String
    let environment: String?
}

struct ThreadMessageRequest: Encodable {
    let text: String
}

struct ThreadCreateRequest: Encodable {
    let provider = "codex"
    let projectId: String
    let permissionMode = "default"
}

struct ApprovalDecisionRequest: Encodable {
    let method: String
    let decision: JSONValue
}

struct ThreadOpenRequest: Encodable {
    let threadId: String
    let mode: String?
}

indirect enum JSONValue: Encodable {
    case string(String)
    case object([String: JSONValue])
    case array([JSONValue])
    case null

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .array(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}

enum AgentPulseWatchError: LocalizedError {
    case missingSession
    case invalidBaseUrl
    case server(String)
    case pairingResetRequired(String)

    var errorDescription: String? {
        switch self {
        case .missingSession:
            return "Pair with Agent Pulse first."
        case .invalidBaseUrl:
            return "Enter a valid helper URL."
        case .server(let message):
            return message
        case .pairingResetRequired(let message):
            return message
        }
    }

    var requiresPairingReset: Bool {
        if case .pairingResetRequired = self {
            return true
        }
        return false
    }
}
