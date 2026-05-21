//
//  RegisterView.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 16/05/26.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var selectedRole: UserRole = .customer

    var body: some View {
        ZStack {
            Color.backgroundColor.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 30) {
                    
                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.textColor)
                        
                        Text("Join Kojek to get started")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)

                    // MARK: - Form Area
                    VStack(spacing: 24) {
                        
                        // 1. Role Picker
                        VStack(alignment: .leading, spacing: 8) {
                            Text("I am joining as a:")
                                .font(.footnote)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            CustomRolePicker(selectedRole: $selectedRole)
                        }
                        
                        // 2. Input Fields
                        VStack(spacing: 16) {
                            KojekTextField(
                                icon: "envelope.fill",
                                placeholder: "Email Address",
                                text: $email,
                                keyboardType: .emailAddress
                            )
                            
                            KojekSecureField(
                                icon: "lock.fill",
                                placeholder: "Create Password",
                                text: $password
                            )
                        }
                    }
                    
                    if let error = auth.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    // MARK: - Action Button
                    Button(action: {
                        Task {
                            await auth.signUp(email: email, password: password, role: selectedRole.databaseValue)
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
                                Text("Sign Up")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(!isFormValid || auth.isLoading)
                    .padding(.top, 10)
                }
                .padding(.horizontal, 24)
            }
        }
        // This removes the default back button text to keep the UI clean when navigating from LandingView
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty && !password.isEmpty
    }
}

// MARK: - Custom Role Picker Component
struct CustomRolePicker: View {
    @Binding var selectedRole: UserRole
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(UserRole.allCases, id: \.self) { role in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedRole = role
                    }
                }) {
                    Text(role.rawValue)
                        .font(.subheadline)
                        .fontWeight(selectedRole == role ? .semibold : .regular)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .foregroundColor(selectedRole == role ? .white : .textColor)
                        .background(selectedRole == role ? Color.primaryColor : Color.clear)
                        .cornerRadius(10)
                }
            }
        }
        .padding(4)
        .background(Color.inputBackgroundColor)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview Environment
#Preview("Registration Flow") {
    RegisterView()
        .environmentObject(AuthViewModel())
}
