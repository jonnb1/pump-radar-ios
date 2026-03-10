// SignUpView.swift
// PumpRadar
//
// Presents the registration form for new users.

import SwiftUI

// MARK: - SignUpView

struct SignUpView: View {

    @ObservedObject var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showPassword = false
    @FocusState private var focusedField: Field?

    private enum Field { case email, username, password, confirmPassword }

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 56))
                        .foregroundColor(.accentColor)
                    Text("Create Account")
                        .font(.largeTitle.bold())
                    Text("Join Pump Radar today")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)

                // Fields
                VStack(spacing: 16) {
                    emailField
                    usernameField
                    passwordField
                    confirmPasswordField

                    if let error = viewModel.errorMessage {
                        errorBanner(message: error)
                    }

                    signUpButton

                    // Back to login
                    Button("Already have an account? Sign In") {
                        dismiss()
                    }
                    .font(.footnote)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal)
            }
        }
        .navigationBarHidden(true)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Subviews

    private var emailField: some View {
        inputField(
            label: "Email",
            icon: "envelope",
            placeholder: "you@example.com",
            text: $viewModel.email,
            field: .email,
            nextField: .username,
            keyboardType: .emailAddress
        )
    }

    private var usernameField: some View {
        inputField(
            label: "Username",
            icon: "person",
            placeholder: "your_username",
            text: $viewModel.username,
            field: .username,
            nextField: .password
        )
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Password", systemImage: "lock")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            HStack {
                Group {
                    if showPassword {
                        TextField("Min. 8 characters", text: $viewModel.password)
                    } else {
                        SecureField("Min. 8 characters", text: $viewModel.password)
                    }
                }
                .focused($focusedField, equals: .password)
                .submitLabel(.next)
                .onSubmit { focusedField = .confirmPassword }
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash" : "eye")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(Constants.UI.cornerRadius)
        }
    }

    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Confirm Password", systemImage: "lock.fill")
                .font(.caption.bold())
                .foregroundColor(.secondary)
            SecureField("Re-enter password", text: $viewModel.confirmPassword)
                .focused($focusedField, equals: .confirmPassword)
                .submitLabel(.go)
                .onSubmit { viewModel.signUp() }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(Constants.UI.cornerRadius)
            if !viewModel.confirmPassword.isEmpty && viewModel.password != viewModel.confirmPassword {
                Text("Passwords do not match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }

    private var signUpButton: some View {
        Button {
            focusedField = nil
            viewModel.signUp()
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text("Create Account")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(viewModel.isSignUpFormValid ? Color.accentColor : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .disabled(!viewModel.isSignUpFormValid || viewModel.isLoading)
    }

    // MARK: - Helpers

    private func inputField(
        label: String,
        icon: String,
        placeholder: String,
        text: Binding<String>,
        field: Field,
        nextField: Field,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: icon)
                .font(.caption.bold())
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .autocapitalization(.none)
                .autocorrectionDisabled()
                .focused($focusedField, equals: field)
                .submitLabel(.next)
                .onSubmit { focusedField = nextField }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(Constants.UI.cornerRadius)
        }
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
            Text(message).font(.footnote).foregroundColor(.red)
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
    SignUpView(viewModel: AuthViewModel())
}
#endif
