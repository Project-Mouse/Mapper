//
//  AuthManager.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import Foundation
import FirebaseAuth

class AuthManager: ObservableObject {

    @Published var user: User?

    private let auth = Auth.auth()

    func signIn(email: String, password: String) async throws {
        try await auth.signIn(withEmail: email, password: password)
        user = auth.currentUser
    }

    func checkForExistingUser() {
        user = auth.currentUser
    }
}
