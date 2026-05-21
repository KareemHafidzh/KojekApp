//
//  KojekLocation.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 17/05/26.
//

import Foundation
import CoreLocation

struct KojekLocation: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let coordinate: CLLocationCoordinate2D
    
    static func == (lhs: KojekLocation, rhs: KojekLocation) -> Bool {
        lhs.id == rhs.id
    }
}
