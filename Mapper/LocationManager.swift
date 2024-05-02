//
//  LocationManager.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import Foundation
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var locations: [LocationData] = []
    @Published var isTracing = false

    private let locationManager = CLLocationManager()

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
    }

    func startTracing() {
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            isTracing = true
        }
    }

    func pauseTracing() {
        locationManager.stopUpdatingLocation()
        isTracing = false
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        let altitude = newLocation.altitude // Access altitude property
        self.locations.append(LocationData(timestamp: newLocation.timestamp, latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude, altitude: altitude))
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location:", error)
    }
}
