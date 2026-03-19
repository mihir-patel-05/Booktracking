import Foundation
import CryptoKit
import Supabase
import AuthenticationServices

@Observable
final class AuthService {
    private let supabase = SupabaseManager.shared.client

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
        do {
            let session = try await supabase.auth.session
            currentUserId = session.user.id.uuidString
            isAuthenticated = true
        } catch {
            isAuthenticated = false
            currentUserId = nil
        }
        isLoading = false
    }

    // MARK: - Sign in with Apple

    func signInWithApple(idToken: String, nonce: String) async throws {
        let session = try await supabase.auth.signInWithIdToken(
            credentials: .init(
                provider: .apple,
                idToken: idToken,
                nonce: nonce
            )
        )
        currentUserId = session.user.id.uuidString
        isAuthenticated = true
    }

    // MARK: - Email/Password Auth

    func signUp(email: String, password: String) async throws {
        let result = try await supabase.auth.signUp(email: email, password: password)
        currentUserId = result.user.id.uuidString
        isAuthenticated = true
    }

    func signIn(email: String, password: String) async throws {
        let session = try await supabase.auth.signIn(email: email, password: password)
        currentUserId = session.user.id.uuidString
        isAuthenticated = true
    }

    // MARK: - Sign Out

    func signOut() async throws {
        try await supabase.auth.signOut()
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
