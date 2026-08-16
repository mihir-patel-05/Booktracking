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

            // Subtle radial accent in the corners
            RadialGradient(
                colors: [Theme.accent.opacity(0.18), Color.clear],
                center: .topTrailing,
                startRadius: 50,
                endRadius: 360
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [Theme.accent.opacity(0.10), Color.clear],
                center: .bottomLeading,
                startRadius: 50,
                endRadius: 320
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    Spacer().frame(height: 30)

                    branding

                    Spacer().frame(height: 4)

                    formCard

                    dividerRow

                    appleButton

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.dmSans(12))
                            .foregroundStyle(Theme.error)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var branding: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.18))
                    .frame(width: 80, height: 80)
                Image(systemName: "book.pages")
                    .font(.system(size: 38))
                    .foregroundStyle(Theme.accentLight)
            }
            .shadow(color: Theme.accentGlow, radius: 18)

            Text("PageFlow")
                .font(.playfair(40, weight: .bold))
                .foregroundStyle(Theme.textPrimary)

            Text("Read. Reflect. Grow.")
                .font(.dmSans(14))
                .foregroundStyle(Theme.textSecondary)
                .tracking(1.5)
        }
    }

    private var formCard: some View {
        VStack(spacing: 14) {
            authField(placeholder: "Email", text: $email, isSecure: false)
            authField(placeholder: "Password", text: $password, isSecure: true)

            Button {
                submitEmailAuth()
            } label: {
                HStack {
                    if isSubmitting {
                        ProgressView().tint(.white)
                    } else {
                        Text(isSignUp ? "Create Account" : "Sign In")
                    }
                }
            }
            .buttonStyle(PrimaryGradientButtonStyle(enabled: !email.isEmpty && !password.isEmpty && !isSubmitting))
            .disabled(email.isEmpty || password.isEmpty || isSubmitting)

            Button {
                isSignUp.toggle()
                errorMessage = nil
            } label: {
                Text(isSignUp ? "Already have an account? Sign in" : "Don't have an account? Sign up")
                    .font(.dmSans(13, weight: .medium))
                    .foregroundStyle(Theme.accentLight)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
    }

    @ViewBuilder
    private func authField(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        let base = Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .textContentType(isSignUp ? .newPassword : .password)
            } else {
                TextField(placeholder, text: text)
                    .textContentType(.emailAddress)
                    #if os(iOS)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    #endif
                    .autocorrectionDisabled()
            }
        }

        base
            .font(.dmSans(15))
            .foregroundStyle(Theme.textPrimary)
            .tint(Theme.accentLight)
            .padding(14)
            .designCard(cornerRadius: 14)
    }

    private var dividerRow: some View {
        HStack(spacing: 12) {
            Rectangle().fill(Theme.border).frame(height: 1)
            Text("or")
                .font(.dmSans(11, weight: .semibold))
                .foregroundStyle(Theme.textMuted)
                .tracking(1.5)
            Rectangle().fill(Theme.border).frame(height: 1)
        }
    }

    private var appleButton: some View {
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
        .cornerRadius(14)
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
