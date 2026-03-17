//
//  AuthFlowView.swift
//  stepTracker
//
//  Created by Codex on 3/17/26.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuthFlowView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 30) {
                    authHeader
                    providerStack
                    guestFooter
                }
                .padding(.horizontal, 22)
                .padding(.top, 22)
                .padding(.bottom, 36)
            }
            .background(SignalBackground())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        closeFlow()
                    }
                }
            }
            .navigationDestination(for: AuthRoute.self) { route in
                switch route {
                case .email:
                    EmailAuthView(closeFlow: closeFlow)
                        .environmentObject(appModel)
                case .google:
                    GoogleAuthView(closeFlow: closeFlow)
                        .environmentObject(appModel)
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(appModel.preferredColorScheme)
        .onDisappear {
            appModel.dismissAuthFlow()
        }
    }

    private var authHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SOCIAL")
                .font(.system(size: 11, weight: .semibold))
                .tracking(2.2)
                .foregroundStyle(appModel.accentColor)

            Text("Connect your account")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .kerning(-0.7)

            Text("Email is ready now. Google can be wired in next without changing the rest of the flow.")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var providerStack: some View {
        VStack(spacing: 14) {
            providerButton(
                title: "Continue with email",
                subtitle: "Sign in or create an account with a password.",
                icon: "at",
                tint: appModel.accentColor
            ) {
                appModel.clearAuthFlowError()
                path.append(AuthRoute.email)
            }

            providerButton(
                title: "Continue with Google",
                subtitle: "Use your Google account once the SDK and URL scheme are wired.",
                icon: "globe",
                tint: Color.primary.opacity(appModel.isDarkTheme ? 0.88 : 0.72)
            ) {
                appModel.clearAuthFlowError()
                path.append(AuthRoute.google)
            }
        }
    }

    private func providerButton(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(appModel.isDarkTheme ? 0.16 : 0.12))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.58 : 0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.primary.opacity(appModel.isDarkTheme ? 0.08 : 0.05), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var guestFooter: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Guest mode still works exactly the same. Only the friends layer depends on account auth.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)

            Button("Continue as guest") {
                closeFlow()
            }
            .buttonStyle(.plain)
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(appModel.accentColor)
        }
    }

    private func closeFlow() {
        appModel.dismissAuthFlow()
        dismiss()
    }
}

private enum AuthRoute: Hashable {
    case email
    case google
}

private struct EmailAuthView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    let closeFlow: () -> Void

    @State private var mode: EmailAuthMode = .signIn
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("EMAIL")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2.2)
                        .foregroundStyle(appModel.accentColor)

                    Text(mode == .signIn ? "Welcome back" : "Create your account")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .kerning(-0.6)

                    Text(mode == .signIn ? "Use your email to unlock rankings and sync later." : "Start with email now. You can keep guest mode for local tracking any time.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                HStack(spacing: 22) {
                    emailModeButton(.signIn, title: "Sign in")
                    emailModeButton(.create, title: "Create")
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 18) {
                    authInputField(title: "Email", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                    authPasswordField

                    if let authFlowErrorMessage = appModel.authFlowErrorMessage {
                        Text(authFlowErrorMessage)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundStyle(.red)
                    }

                    Button(primaryActionTitle) {
                        Task {
                            if mode == .signIn {
                                await appModel.signInWithEmail(email: email, password: password)
                            } else {
                                await appModel.createAccount(email: email, password: password)
                            }

                            if appModel.isSignedIn {
                                closeFlow()
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(appModel.isDarkTheme ? .white : .black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(appModel.accentColor)
                    )
                    .opacity(canSubmit ? 1 : 0.45)
                    .disabled(!canSubmit || appModel.isAuthSubmitting)
                }

                Button("Back") {
                    appModel.clearAuthFlowError()
                    dismiss()
                }
                .buttonStyle(.plain)
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 36)
        }
        .background(SignalBackground())
    }

    private func emailModeButton(_ target: EmailAuthMode, title: String) -> some View {
        Button {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.88)) {
                mode = target
                appModel.clearAuthFlowError()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.system(size: 22, weight: mode == target ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(mode == target ? Color.primary : .secondary)

                Capsule(style: .continuous)
                    .fill(mode == target ? appModel.accentColor : Color.primary.opacity(0.10))
                    .frame(width: mode == target ? 30 : 16, height: 3)
            }
        }
        .buttonStyle(.plain)
    }

    private func authInputField(
        title: String,
        text: Binding<String>,
        keyboardType: UIKeyboardType,
        textContentType: UITextContentType
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(appModel.accentColor)

            TextField("", text: text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.56 : 0.78))
                )
        }
    }

    private var authPasswordField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Password")
                .font(.system(size: 12, weight: .semibold))
                .tracking(1.8)
                .foregroundStyle(appModel.accentColor)

            SecureField("", text: $password)
                .textContentType(mode == .signIn ? .password : .newPassword)
                .font(.system(size: 18, weight: .medium, design: .rounded))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.56 : 0.78))
                )
        }
    }

    private var primaryActionTitle: String {
        mode == .signIn ? "Sign in with email" : "Create account"
    }

    private var canSubmit: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && password.count >= 6
    }
}

private enum EmailAuthMode {
    case signIn
    case create
}

private struct GoogleAuthView: View {
    @EnvironmentObject private var appModel: AppModel
    @Environment(\.dismiss) private var dismiss

    let closeFlow: () -> Void

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GOOGLE")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(2.2)
                        .foregroundStyle(appModel.accentColor)

                    Text("Google sign-in needs one more setup pass")
                        .font(.system(size: 31, weight: .bold, design: .rounded))
                        .kerning(-0.6)

                    Text("The UI flow is ready, but the GoogleSignIn SDK and iOS URL scheme still need to be wired into the Firebase project and app target.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 14) {
                    googleStepRow(number: "01", text: "Enable Google in Firebase Authentication.")
                    googleStepRow(number: "02", text: "Add the GoogleSignIn package to the project.")
                    googleStepRow(number: "03", text: "Wire the reversed client ID URL scheme into the app target.")
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(appModel.surfaceColor.opacity(appModel.isDarkTheme ? 0.58 : 0.78))
                )

                if let authFlowErrorMessage = appModel.authFlowErrorMessage {
                    Text(authFlowErrorMessage)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.red)
                }

                Button("Try Google sign-in") {
                    appModel.signInWithGoogle()
                }
                .buttonStyle(.plain)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(appModel.isDarkTheme ? .white.opacity(0.86) : .black.opacity(0.72))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.primary.opacity(appModel.isDarkTheme ? 0.10 : 0.08))
                )

                HStack(spacing: 18) {
                    Button("Back") {
                        appModel.clearAuthFlowError()
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)

                    Button("Continue as guest") {
                        closeFlow()
                    }
                    .buttonStyle(.plain)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(appModel.accentColor)
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 36)
        }
        .background(SignalBackground())
    }

    private func googleStepRow(number: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(appModel.accentColor)
                .frame(width: 30, alignment: .leading)

            Text(text)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(.primary)

            Spacer()
        }
    }
}

struct AuthFlowView_Previews: PreviewProvider {
    static var previews: some View {
        AuthFlowView()
            .environmentObject(AppModel(stepDataService: PreviewStepDataService()))
    }
}
