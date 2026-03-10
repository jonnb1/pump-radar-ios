// LoginView.swift
// PumpRadar
//
// Presents email/password fields for signing into an existing account.

import SwiftUI

// MARK: - LoginView

struct LoginView: View {

    @ObservedObject var viewModel: AuthViewModel
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, password }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo / Header
                header

                // Form
                VStack(spacing: 16) {
                    emailField
                    passwordField
                    if let error = viewModel.errorMessage {
                        errorBanner(message: error)
                    }
                    loginButton
                }
                .padding(.horizontal)
            }
            .padding(.top, 40)
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            Text("Pump Radar")
                .font(.largeTitle.bold())
            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var emailField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Email", systemImage: "envelope")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            TextField("you@example.com", text: $viewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit { focusedField = .password }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(Constants.UI.cornerRadius)
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Password", systemImage: "lock")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            HStack {
                Group {
                    if showPassword {
                        TextField("••••••••", text: $viewModel.password)
                    } else {
                        SecureField("••••••••", text: $viewModel.password)
                    }
                }
                .focused($focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit { viewModel.login() }
                Button {
                    showPassword.toggle()
                } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }

    private var loginButton: some View {
        Button {
            focusedField = nil
            viewModel.login()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Sign In")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isLoginFormValid ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .disabled(!viewModel.isLoginFormValid || viewModel.isLoading)
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            Text(message)
                .font(.footnote)
                .foregroundColor(.red)
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    NavigationView {
        LoginView(viewModel: AuthViewModel())
    }
}
#endif
