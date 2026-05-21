//
//  LoginView.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 16/05/26.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var auth: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        ZStack {
            Color.backgroundColor.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // MARK: - Header / Logo Area
                    VStack(spacing: 12) {
                        Image(systemName: "paperplane.fill") // Replace with Kojek Logo
                            .font(.system(size: 50))
                            .foregroundColor(.primaryColor)
                            .padding(.bottom, 10)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textColor)
                        
                        Text("Sign in to continue to Kojek")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 20)

                    // MARK: - Input Fields
                    VStack(spacing: 16) {
                        KojekTextField(
                            icon: "envelope.fill",
                            placeholder: "Email Address",
                            text: $email,
                            keyboardType: .emailAddress
                        )
                        
                        KojekSecureField(
                            icon: "lock.fill",
                            placeholder: "Password",
                            text: $password
                        )
                    }
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                            .transition(.opacity)
                    }

                    // MARK: - Action Buttons
                    VStack(spacing: 20) {
                        
                        // 1. Primary Sign In Button
                        Button(action: {
                            Task {
                                await auth.signIn(email: email, password: password)
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isFormValid ? Color.primaryColor : Color.primaryColor.opacity(0.5))
                                    .frame(height: 56)
                                
                                if auth.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                        .disabled(!isFormValid || auth.isLoading)

                        // 2. Navigation to RegisterView
                        NavigationLink(destination: RegisterView()) {
                            HStack(spacing: 4) {
                                Text("Don't have an account?")
                                    .foregroundColor(.gray)
                                Text("Sign Up")
                                    .fontWeight(.bold)
                                    .foregroundColor(.primaryColor)
                            }
                            .font(.footnote)
                        }
                        .disabled(auth.isLoading)
                        // Clear error message when leaving the view
                        .simultaneousGesture(TapGesture().onEnded {
                            auth.errorMessage = nil
                        })
                    }
                    .padding(.top, 10)
                    
                }
                .padding(.horizontal, 24)
            }
        }
        // Hides the default navigation bar back button text if coming from a Landing View
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
}

// MARK: - Reusable Custom Components

struct KojekTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .foregroundColor(Color.textColor)
        }
        .padding()
        .background(Color.inputBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

struct KojekSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            if isVisible {
                TextField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .foregroundColor(Color.textColor)
            } else {
                SecureField(placeholder, text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .foregroundColor(Color.textColor)
            }
            
            Button(action: { isVisible.toggle() }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.inputBackgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview Environment
#Preview("Login - Standard") {
    // Wrapped in NavigationView so the NavigationLink works in the canvas
    NavigationView {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}

#Preview("Login - Error") {
    NavigationView {
        let mockAuth = AuthViewModel()
        mockAuth.errorMessage = "The email address is badly formatted."
        return LoginView()
            .environmentObject(mockAuth)
    }
}
