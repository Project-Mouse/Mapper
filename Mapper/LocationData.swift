//
//  LocationData.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import Foundation
import CoreLocation

struct LocationData: Identifiable {
    let id: UUID = UUID()
    let timestamp: Date
    let latitude: CLLocationDegrees
    let longitude: CLLocationDegrees
    var altitude: Double // Add altitude property
    
    var description: String {
            return "Latitude: \(latitude), Longitude: \(longitude)"
        }
}
