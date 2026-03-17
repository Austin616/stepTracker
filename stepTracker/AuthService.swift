//
//  AuthService.swift
//  stepTracker
//
//  Created by Codex on 3/16/26.
//

import Foundation

#if canImport(FirebaseAuth)
import FirebaseAuth
#endif

struct AuthSession: Equatable {
    let userID: String
    let isAnonymous: Bool
}

enum AuthServiceError: LocalizedError {
    case firebaseNotConfigured
    case unsupportedProvider

    var errorDescription: String? {
        switch self {
        case .firebaseNotConfigured:
            return "Firebase is not configured."
        case .unsupportedProvider:
            return "This sign-in provider is not available yet."
        }
    }
}

protocol AuthProviding {
    var providerName: String { get }
    var isConfigured: Bool { get }
    func currentSession() -> AuthSession?
    func signInForSocialMode() async throws -> AuthSession
    func signIn(email: String, password: String) async throws -> AuthSession
    func createAccount(email: String, password: String) async throws -> AuthSession
    func signOut() throws
}

enum AuthServiceFactory {
    static func make() -> AuthProviding {
        #if canImport(FirebaseAuth)
        if FirebaseBootstrap.isConfigured {
            return FirebaseAuthService()
        }
        #endif
        return LocalAuthService()
    }
}

private final class LocalAuthService: AuthProviding {
    private var session: AuthSession?

    var providerName: String { "Local" }
    var isConfigured: Bool { true }

    func currentSession() -> AuthSession? {
        session
    }

    func signInForSocialMode() async throws -> AuthSession {
        let newSession = AuthSession(userID: UUID().uuidString, isAnonymous: false)
        session = newSession
        return newSession
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        throw AuthServiceError.unsupportedProvider
    }

    func createAccount(email: String, password: String) async throws -> AuthSession {
        throw AuthServiceError.unsupportedProvider
    }

    func signOut() throws {
        session = nil
    }
}

#if canImport(FirebaseAuth)
private final class FirebaseAuthService: AuthProviding {
    var providerName: String { "Firebase Auth" }
    var isConfigured: Bool { FirebaseBootstrap.isConfigured }

    func currentSession() -> AuthSession? {
        guard let user = Auth.auth().currentUser else { return nil }
        return AuthSession(userID: user.uid, isAnonymous: user.isAnonymous)
    }

    func signInForSocialMode() async throws -> AuthSession {
        guard FirebaseBootstrap.isConfigured else {
            throw AuthServiceError.firebaseNotConfigured
        }
        let result = try await Auth.auth().signInAnonymously()
        return AuthSession(userID: result.user.uid, isAnonymous: result.user.isAnonymous)
    }

    func signIn(email: String, password: String) async throws -> AuthSession {
        guard FirebaseBootstrap.isConfigured else {
            throw AuthServiceError.firebaseNotConfigured
        }
        let result = try await Auth.auth().signIn(withEmail: email, password: password)
        return AuthSession(userID: result.user.uid, isAnonymous: result.user.isAnonymous)
    }

    func createAccount(email: String, password: String) async throws -> AuthSession {
        guard FirebaseBootstrap.isConfigured else {
            throw AuthServiceError.firebaseNotConfigured
        }
        let result = try await Auth.auth().createUser(withEmail: email, password: password)
        return AuthSession(userID: result.user.uid, isAnonymous: result.user.isAnonymous)
    }

    func signOut() throws {
        try Auth.auth().signOut()
    }
}
#endif
