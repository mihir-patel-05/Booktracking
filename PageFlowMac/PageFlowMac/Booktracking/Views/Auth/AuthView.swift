import SwiftUI
import AuthenticationServices

struct AuthView: View {
    @Environment(AuthService.self) private var authService

    @State private var currentNonce: String?
    @State private var errorMessage: String?
    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var isSubmitting = false

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    Spacer().frame(height: 40)

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

                    Spacer().frame(height: 20)

                    // Email/Password form
                    VStack(spacing: 16) {
                        TextField("Email", text: $email)
                            .textContentType(.emailAddress)
                            .autocorrectionDisabled()
                            .padding()
                            .background(Theme.cardBackground)
                            .foregroundStyle(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        SecureField("Password", text: $password)
                            .textContentType(isSignUp ? .newPassword : .password)
                            .padding()
                            .background(Theme.cardBackground)
                            .foregroundStyle(Theme.textPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                        Button {
                            submitEmailAuth()
                        } label: {
                            HStack {
                                if isSubmitting {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(Theme.accent)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                        .disabled(email.isEmpty || password.isEmpty || isSubmitting)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1.0)

                        Button {
                            isSignUp.toggle()
                            errorMessage = nil
                        } label: {
                            Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                                .font(.subheadline)
                                .foregroundStyle(Theme.accentLight)
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: 400)

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Theme.textMuted)
                            .frame(height: 1)
                        Text("or")
                            .font(.subheadline)
                            .foregroundStyle(Theme.textMuted)
                        Rectangle()
                            .fill(Theme.textMuted)
                            .frame(height: 1)
                    }
                    .frame(maxWidth: 400)

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
                    }
                    .frame(maxWidth: 400)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(Theme.error)
                            .frame(maxWidth: 400)
                    }

                    Spacer().frame(height: 40)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func submitEmailAuth() {
        isSubmitting = true
        errorMessage = nil

        Task {
            do {
                if isSignUp {
                    try await authService.signUp(email: email, password: password)
                } else {
                    try await authService.signIn(email: email, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSubmitting = false
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
