//
//  UserModel.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 17/05/26.
//

import Foundation

enum UserRole: String, CaseIterable, Codable {
    case customer = "Customer"
    case driver = "Driver Partner"
    
    // Translates UI text to the Supabase database expected text
    var databaseValue: String {
        switch self {
        case .customer: return "customer"
        case .driver: return "driver"
        }
    }
}

struct UserProfile: Codable {
    let id: UUID
    let email: String
    let role: String
}
