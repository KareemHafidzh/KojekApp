//
//  AuthViewModel.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 16/05/26.
//

import SwiftUI
import Combine
import Supabase

class AuthViewModel: ObservableObject {  // ← remove @MainActor here
    @Published var session: Session? = nil
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var currentUserRole: UserRole = .customer

    init() {
        Task {
            await fetchSession()
            observeAuthChanges()
        }
    }

    func fetchSession() async {
        let s = try? await supabase.auth.session
        await MainActor.run {
            self.session = s
            self.extractRole(from: s)
        }
    }

    func observeAuthChanges() {
        Task {
            for await (_, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    self.session = session
                    self.extractRole(from: session)
                }
            }
        }
    }

    private func extractRole(from session: Session?) {
        guard let currentSession = session else { return }
        if let metadataRole = currentSession.user.userMetadata["role"],
           case let .string(roleString) = metadataRole {
                print("🔍 Role from metadata: \(roleString)")
                print("🔍 Driver databaseValue: \(UserRole.driver.databaseValue)")
                print("🔍 Driver rawValue: \(UserRole.driver.rawValue)")
                self.currentUserRole = UserRole.allCases.first(where: { $0.rawValue == roleString }) ?? .customer
            }
    }

    func signUp(email: String, password: String, role: String) async {
        // Validate before hitting Supabase
        if let emailError = validateEmail(email) {
            errorMessage = emailError
            return
        }
        if let passwordError = validatePassword(password) {
            errorMessage = passwordError
            return
        }

        isLoading = true
        defer { isLoading = false }
        do {
            let metadata: [String: AnyJSON] = ["role": .string(role)]
            try await supabase.auth.signUp(email: email, password: password, data: metadata)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signIn(email: String, password: String) async {
        if let emailError = validateEmail(email) { errorMessage = emailError; return }
        if let passwordError = validatePassword(password) { errorMessage = passwordError; return }

        await MainActor.run { isLoading = true }
        defer { Task { await MainActor.run { self.isLoading = false } } }
        do {
            try await supabase.auth.signIn(email: email, password: password)
        } catch {
            await MainActor.run { self.errorMessage = mapSupabaseError(error) }
        }
    }

    func signOut() async {
        try? await supabase.auth.signOut()
        await MainActor.run {
            self.session = nil
            self.currentUserRole = .customer
        }
    }

    // MARK: - Validation
    private func validateEmail(_ email: String) -> String? {
        let trimmed = email.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return "Email cannot be empty." }
        let regex = #"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$"#
        guard trimmed.range(of: regex, options: .regularExpression) != nil else {
            return "Please enter a valid email address."
        }
        return nil
    }

    private func validatePassword(_ password: String) -> String? {
        guard !password.isEmpty else { return "Password cannot be empty." }
        guard password.count >= 6 else { return "Password must be at least 6 characters." }
        return nil
    }

    private func mapSupabaseError(_ error: Error) -> String {
        let message = error.localizedDescription.lowercased()
        if message.contains("invalid login credentials") { return "Incorrect email or password." }
        if message.contains("already registered") { return "This email is already registered." }
        if message.contains("network") { return "No internet connection." }
        if message.contains("rate limit") { return "Too many attempts. Please wait." }
        return error.localizedDescription
    }
}
