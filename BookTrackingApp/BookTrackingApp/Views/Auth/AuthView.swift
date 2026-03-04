import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthService.self) private var authService

    @State private var currentNonce: String?
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // App branding
                VStack(spacing: 16) {
                    Image(systemName: "book.pages")
                        .font(.system(size: 64))
                        .foregroundStyle(Theme.accent)

                    Text("PageFlow")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)

                    Text("Read. Reflect. Grow.")
                        .font(.title3)
                        .foregroundStyle(Theme.textSecondary)
                }

                Spacer()

                // Sign in with Apple
                VStack(spacing: 16) {
                    SignInWithAppleButton(.signIn) { request in
                        let nonce = AuthService.randomNonceString()
                        currentNonce = nonce
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = AuthService.sha256(nonce)
                    } onCompletion: { result in
                        handleSignInResult(result)
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(12)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Theme.error)
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
                    .frame(height: 60)
            }
        }
    }

    private func handleSignInResult(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard
                let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = appleIDCredential.identityToken,
                let idToken = String(data: identityTokenData, encoding: .utf8),
                let nonce = currentNonce
            else {
                errorMessage = "Failed to get Apple ID credentials."
                return
            }

            Task {
                do {
                    try await authService.signInWithApple(idToken: idToken, nonce: nonce)
                } catch {
                    errorMessage = "Sign in failed: \(error.localizedDescription)"
                }
            }

        case .failure(let error):
            errorMessage = "Sign in failed: \(error.localizedDescription)"
        }
    }
}
