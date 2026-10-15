import ArgumentParser
import Foundation

enum AXCachePolicy: String, CaseIterable, ExpressibleByArgument {
    case perBatch
    case perStep
    case none
}

enum TypeSubmissionMode: String, CaseIterable, ExpressibleByArgument {
    case chunked
    case composite
}

@MainActor
final class BatchContext {
    let simulatorUDID: String
    let axCachePolicy: AXCachePolicy
    let typeSubmissionMode: TypeSubmissionMode
    let typeChunkSize: Int
    let tapStyle: TapStyle
    let waitTimeout: TimeInterval
    let pollInterval: TimeInterval
    let cachesCoordinateMapping: Bool

    private var cachedRoots: [AccessibilityElement]?
    private var cachedMapping: CoordinateMapping?

    init(
        simulatorUDID: String,
        axCachePolicy: AXCachePolicy,
        typeSubmissionMode: TypeSubmissionMode,
        typeChunkSize: Int,
        tapStyle: TapStyle = .automatic,
        waitTimeout: TimeInterval = 0,
        pollInterval: TimeInterval = 0.25,
        cachesCoordinateMapping: Bool? = nil
    ) {
        self.simulatorUDID = simulatorUDID
        self.axCachePolicy = axCachePolicy
        self.typeSubmissionMode = typeSubmissionMode
        self.typeChunkSize = typeChunkSize
        self.tapStyle = tapStyle
        self.waitTimeout = waitTimeout
        self.pollInterval = pollInterval
        self.cachesCoordinateMapping = cachesCoordinateMapping ?? (axCachePolicy == .perBatch)
    }

    func accessibilityRoots(logger: AxeLogger, forceRefresh: Bool = false) async throws -> [AccessibilityElement] {
        switch axCachePolicy {
        case .none:
            return try await AccessibilityFetcher.fetchAccessibilityElements(for: simulatorUDID, logger: logger)
        case .perStep:
            return try await AccessibilityFetcher.fetchAccessibilityElements(for: simulatorUDID, logger: logger)
        case .perBatch:
            if !forceRefresh, let cachedRoots {
                return cachedRoots
            }
            let roots = try await AccessibilityFetcher.fetchAccessibilityElements(for: simulatorUDID, logger: logger)
            cachedRoots = roots
            return roots
        }
    }

    /// The coordinate mapping is a property of the simulator's orientation, not of the screen
    /// contents, so a perBatch cache reuses it across steps instead of re-probing per step.
    func coordinateMapping(logger: AxeLogger) async throws -> CoordinateMapping {
        if cachesCoordinateMapping, let cachedMapping {
            return cachedMapping
        }
        let roots = try await accessibilityRoots(logger: logger)
        let mapping = try await OrientationAwareCoordinates.detectMapping(
            from: roots,
            simulatorUDID: simulatorUDID,
            logger: logger
        )
        if cachesCoordinateMapping {
            cachedMapping = mapping
        }
        return mapping
    }

    func translate(_ point: (x: Double, y: Double), logger: AxeLogger) async throws -> (x: Double, y: Double) {
        OrientationAwareCoordinates.applyMapping(try await coordinateMapping(logger: logger), to: point, logger: logger)
    }
}
