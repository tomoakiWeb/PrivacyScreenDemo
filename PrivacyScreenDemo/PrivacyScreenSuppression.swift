import Foundation

@preconcurrency
@MainActor
enum PrivacyScreenSuppression {
    private(set) static var isSuppressed = false

    static func setSuppressed(_ value: Bool) {
        isSuppressed = value
    }

    static func suppress<T>(during operation: () async throws -> T) async rethrows -> T {
        isSuppressed = true
        defer { isSuppressed = false }
        return try await operation()
    }
}
