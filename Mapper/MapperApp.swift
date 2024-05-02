//
//  MapperApp.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}


@main
struct MapperApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authManager = AuthManager()
    
    var body: some Scene {
        WindowGroup {
            if authManager.user != nil {
                ContentView()
            } else {
                SignInView()
                    .environmentObject(authManager)
                    .onAppear {
                            authManager.checkForExistingUser()
                        }
            }
            
        }
    }
}
