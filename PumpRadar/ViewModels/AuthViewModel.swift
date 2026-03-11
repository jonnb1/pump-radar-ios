// AuthViewModel.swift
// PumpRadar
//
// Drives the Login and Sign Up screens; propagates authentication state
// to the rest of the app via the shared AuthService.

import Foundation
import Combine

// MARK: - AuthViewModel

@MainActor
final class AuthViewModel: ObservableObject {

    // MARK: - Published State

    @Published var email = ""
    @Published var username = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    @Published var currentUser: User?

    // MARK: - Dependencies

    private let authService: AuthServiceProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialiser

    init(authService: AuthServiceProtocol = AuthService()) {
        self.authService = authService
        authService.currentUser
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                self?.currentUser = user
                self?.isAuthenticated = user != nil
            }
            .store(in: &cancellables)
    }

    // MARK: - Validation

    /// Returns true when the login form fields contain valid non-empty values.
    var isLoginFormValid: Bool {
        email.isNotEmpty && password.count >= 8
    }

    /// Returns true when all sign-up form fields are valid and passwords match.
    var isSignUpFormValid: Bool {
        email.isNotEmpty &&
        username.isNotEmpty &&
        password.count >= 8 &&
        password == confirmPassword
    }

    // MARK: - Actions

    /// Attempts to authenticate an existing user.
    func login() {
        guard isLoginFormValid else {
            errorMessage = "Please enter a valid email and a password of at least 8 characters."
            return
        }
        isLoading = true
        errorMessage = nil
        authService.login(email: email.trimmingCharacters(in: .whitespaces), password: password)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = error.errorDescription
                }
            } receiveValue: { _ in
                // State update handled via currentUser publisher
            }
            .store(in: &cancellables)
    }

    /// Creates a new account for the user.
    func signUp() {
        guard isSignUpFormValid else {
            if password != confirmPassword {
                errorMessage = "Passwords do not match."
            } else {
                errorMessage = "Please fill in all fields with valid values."
            }
            return
        }
        isLoading = true
        errorMessage = nil
        authService.signUp(
            email: email.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces),
            password: password
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] completion in
            self?.isLoading = false
            if case .failure(let error) = completion {
                self?.errorMessage = error.errorDescription
            }
        } receiveValue: { _ in }
        .store(in: &cancellables)
    }

    /// Signs the current user out and clears all session data.
    func logout() {
        authService.logout()
        clearFields()
    }

    // MARK: - Private Helpers

    private func clearFields() {
        email = ""
        username = ""
        password = ""
        confirmPassword = ""
        errorMessage = nil
    }
}
