import SwiftUI

struct AuthenticationView: View {
    @State private var isSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    @EnvironmentObject var networkService: NetworkService
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [.purple, .blue, .black]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        Spacer(minLength: 60)
                        
                        // Logo and title
                        VStack(spacing: 16) {
                            Image(systemName: "video.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.white)
                            
                            Text("StreamUp")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Go live instantly with friends")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        
                        // Auth form
                        VStack(spacing: 20) {
                            if isSignUp {
                                signUpForm
                            } else {
                                loginForm
                            }
                            
                            if let errorMessage = errorMessage {
                                Text(errorMessage)
                                    .foregroundColor(.red)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)
                            }
                            
                            // Action button
                            Button(action: {
                                Task {
                                    await authenticate()
                                }
                            }) {
                                HStack {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    }
                                    
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1.0 : 0.6)
                            
                            // Toggle between login/signup
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    isSignUp.toggle()
                                    clearForm()
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Text(isSignUp ? "Already have an account?" : "Don't have an account?")
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Text(isSignUp ? "Sign In" : "Sign Up")
                                        .foregroundColor(.purple)
                                        .fontWeight(.semibold)
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
        }
    }
    
    private var loginForm: some View {
        VStack(spacing: 16) {
            AuthTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            AuthTextField(
                placeholder: "Password",
                text: $password,
                icon: "lock",
                isSecure: true,
                textContentType: .password
            )
        }
    }
    
    private var signUpForm: some View {
        VStack(spacing: 16) {
            AuthTextField(
                placeholder: "Username",
                text: $username,
                icon: "person",
                textContentType: .username
            )
            
            AuthTextField(
                placeholder: "Display Name",
                text: $displayName,
                icon: "person.badge.plus",
                textContentType: .name
            )
            
            AuthTextField(
                placeholder: "Email",
                text: $email,
                icon: "envelope",
                keyboardType: .emailAddress,
                textContentType: .emailAddress
            )
            
            AuthTextField(
                placeholder: "Password",
                text: $password,
                icon: "lock",
                isSecure: true,
                textContentType: .newPassword
            )
            
            AuthTextField(
                placeholder: "Confirm Password",
                text: $confirmPassword,
                icon: "lock.fill",
                isSecure: true,
                textContentType: .newPassword
            )
        }
    }
    
    private var isFormValid: Bool {
        if isSignUp {
            return !username.isEmpty &&
                   !displayName.isEmpty &&
                   !email.isEmpty &&
                   !password.isEmpty &&
                   !confirmPassword.isEmpty &&
                   password == confirmPassword &&
                   password.count >= 6 &&
                   email.contains("@")
        } else {
            return !email.isEmpty &&
                   !password.isEmpty &&
                   email.contains("@")
        }
    }
    
    private func authenticate() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isSignUp {
                _ = try await networkService.register(
                    username: username,
                    email: email,
                    password: password,
                    displayName: displayName
                )
            } else {
                _ = try await networkService.login(email: email, password: password)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func clearForm() {
        email = ""
        password = ""
        username = ""
        displayName = ""
        confirmPassword = ""
        errorMessage = nil
    }
}

struct AuthTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    var isSecure: Bool = false
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 20)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textContentType(textContentType)
            } else {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboardType)
                    .textContentType(textContentType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .foregroundColor(.white)
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(NetworkService.shared)
}