import Foundation
import FirebaseCore

enum FirebaseConfigurationError: LocalizedError {
    case missingGoogleServiceInfo

    var errorDescription: String? {
        switch self {
        case .missingGoogleServiceInfo:
            "Missing GoogleService-Info.plist. Add the file from your Firebase project to the app target before using cloud sync or authentication."
        }
    }
}

@Observable
final class FirebaseManager {
    static let shared = FirebaseManager()

    private(set) var isConfigured = false

    private init() {
        configureIfPossible()
    }

    @discardableResult
    func configureIfPossible() -> Bool {
        if FirebaseApp.app() != nil {
            isConfigured = true
            return true
        }

        guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else {
            isConfigured = false
            return false
        }

        FirebaseApp.configure()
        isConfigured = FirebaseApp.app() != nil
        return isConfigured
    }

    func requireConfigured() throws {
        guard configureIfPossible() else {
            throw FirebaseConfigurationError.missingGoogleServiceInfo
        }
    }
}
