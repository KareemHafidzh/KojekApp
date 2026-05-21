//
//  KojekApp.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 16/05/26.
//

import SwiftUI

@main
struct YourApp: App {
    @StateObject private var auth = AuthViewModel()
    

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.session != nil {
                    switch auth.currentUserRole {
                    case .customer:
                        CustomerHomeView()
                    case .driver:
                        DriverHomeView()
                    }
                } else {
                    NavigationView {
                        LoginView()
                    }
                }
            }
            .environmentObject(auth)
            .animation(.easeInOut, value: auth.session != nil)
        }
    }
}
