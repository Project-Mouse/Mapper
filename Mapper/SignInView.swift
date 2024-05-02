//
//  SignInView.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import SwiftUI

struct SignInView: View {

    @State private var email = ""
    @State private var password = ""
    @State private var error: Error? = nil

    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        NavigationStack{
            Form {
                TextField("Email", text: $email)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                SecureField("Password", text: $password)
                
                Section{
                    Button("Sign In") {
                        Task {
                            do {
                                try await authManager.signIn(email: email, password: password)
                            } catch {
                                self.error = error
                            }
                        }
                    }
                }
                if let error = error {
                    Text(error.localizedDescription)
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Sign In")
        }
        .navigationTitle("Sign In")
    }
}

#Preview {
    SignInView()
}
