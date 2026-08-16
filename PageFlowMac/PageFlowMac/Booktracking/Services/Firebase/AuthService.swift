import Foundation
import CryptoKit
import FirebaseAuth
import AuthenticationServices

@Observable
final class AuthService {
    private let firebase = FirebaseManager.shared

    var currentUserId: String?
    var isAuthenticated = false
    var isLoading = true

    init() {
        Task {
            await checkSession()
        }
    }

    // MARK: - Session Management

    func checkSession() async {
        guard firebase.configureIfPossible() else {
            isAuthenticated = false
            currentUserId = nil
            isLoading = false
            return
        }

        if let user = Auth.auth().currentUser {
            currentUserId = user.uid
            isAuthenticated = true
        } else {
            currentUserId = nil
            isAuthenticated = false
        }

        isLoading = false
    }

    // MARK: - Sign in with Apple

    func signInWithApple(
        idToken: String,
        nonce: String,
        fullName: PersonNameComponents? = nil
    ) async throws {
        try firebase.requireConfigured()

        let credential = OAuthProvider.appleCredential(
            withIDToken: idToken,
            rawNonce: nonce,
            fullName: fullName
        )
        let result = try await Auth.auth().signIn(with: credential)
        currentUserId = result.user.uid
        isAuthenticated = true
    }

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String) async throws {
        try firebase.requireConfigured()

        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        currentUserId = result.user.uid
        isAuthenticated = true
    }

    func signIn(email: String, password: String) async throws {
        try firebase.requireConfigured()

        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        currentUserId = result.user.uid
        isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try firebase.requireConfigured()

        try Auth.auth().signOut()
        currentUserId = nil
        isAuthenticated = false
    }

    // MARK: - Nonce Helpers

    static func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        var randomBytes = [UInt8](repeating: 0, count: length)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String(randomBytes.map { charset[Int($0) % charset.count] })
    }

    static func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        return hashedData.compactMap { String(format: "%02x", $0) }.joined()
    }
}
