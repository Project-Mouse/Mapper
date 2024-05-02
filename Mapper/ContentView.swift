//
//  ContentView.swift
//  Mapper
//
//  Created by Imran razak on 23/04/2024.
//

import SwiftUI
import MapKit
import FirebaseFirestore
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showPOIForm = false
    @State private var pois: [POI] = []
    @State private var locationText = ""
    @State private var RouteType = ""
    @State private var totalDistance: CLLocationDistance = 0
    @State private var totalElevationChange: CLLocationDistance = 0 // Add state variables for totalDistance and totalElevationChange
    
    
    
    @State private var selectedLocation: CLLocationCoordinate2D?
    @State private var poiRouteCoordinates: [[String: Double]] = [] // Declare poiRouteCoordinates
    @State private var selectedPOI: String = "Toilet" // Declare selectedPOI
    
    let db = Firestore.firestore()
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Add Location")) {
                    TextField("Location", text: $locationText)
                    TextField("Route Type", text: $RouteType)
                }
                Section(header: Text("Mapping")) {
                    MapView(locations: locationManager.locations)                    .frame(height: 300)
                    .cornerRadius(12)
                    Button(locationManager.isTracing ? "Pause Tracing" : "Start Tracing") {
                        if locationManager.isTracing {
                            locationManager.pauseTracing()
                        } else {
                            locationManager.startTracing()
                        }
                    }
                }
                Section(header: Text("Route Details")) {
                    Text("Total Distance: \(String(format: "%.2f", totalDistance)) meters")
                    Text("Total Elevation Change: \(String(format: "%.2f", totalElevationChange)) meters")
                }
                
                
                Section(header: Text("POI")) {
                    ForEach(pois, id: \.self) { poi in
                        Text(poi.name) // Display POI name
                    }
                    Button(action: {
                        showPOIForm = true
                    }) {
                        Label("Add POI", systemImage: "plus")
                    }
                }
                
                Section(header: Text("Logged Coordinates")) {
                    ForEach(locationManager.locations) { location in
                        Text(String(format: "%.6f, %.6f (%@)", location.latitude, location.longitude, location.timestamp.formatted(date: .omitted, time: .shortened)))
                    }
                }
                
                Button {
                    if Reachability.isConnectedToNetwork() {
                        let routeData = prepareRouteData(selectedPOI: selectedPOI, poiRouteCoordinates: poiRouteCoordinates)
                        submitLocationsToFirestore(routeData: routeData, poiRouteCoordinates: poiRouteCoordinates, selectedPOI: selectedPOI, totalDistance: totalDistance, totalElevationChange: totalElevationChange)
                    } else {
                        saveToUserDefaults(data: prepareRouteData(selectedPOI: selectedPOI, poiRouteCoordinates: poiRouteCoordinates))
                    }
                    resetView()
                } label: {
                    Text("Submit")
                }
                
            }
            .navigationTitle("Mapper")
            .sheet(isPresented: $showPOIForm) {
                POIView(pois: $pois, showPOIForm: $showPOIForm, poiRouteCoordinates: $poiRouteCoordinates, selectedPOI: $selectedPOI)
            }
            .onReceive(locationManager.$locations, perform: { locations in
                        calculateTotalDistanceAndElevation(locations)
                    })
            
        }
    }
    
    func submitLocationsToFirestore(routeData: [String: Any], poiRouteCoordinates: [[String: Double]], selectedPOI: String?, totalDistance: CLLocationDistance, totalElevationChange: CLLocationDistance) {
        let routeCoordinates = locationManager.locations.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        
        guard let firstLocation = locationManager.locations.first,
              let lastLocation = locationManager.locations.last else {
            print("No locations to submit.")
            return
        }
        
        let docRef = db.collection("locations").document() // Create document reference
        
        // Prepare data for the document
        var updatedRouteData = routeData
        updatedRouteData["poiRoute"] = poiRouteCoordinates // Include POI route coordinates
        updatedRouteData["selectedPOI"] = selectedPOI // Include selected POI
        updatedRouteData["totalDistance"] = totalDistance // Include total distance
        updatedRouteData["totalElevationChange"] = totalElevationChange // Include total elevation change
        
        // Save to UserDefaults
        saveToUserDefaults(data: updatedRouteData)
        
        // Add data to the document
        docRef.setData(updatedRouteData) { error in
            if let error = error {
                print("Error writing route: \(error.localizedDescription)")
            } else {
                print("Route and additional data successfully submitted!")
            }
        }
    }

    func prepareRouteData(selectedPOI: String?, poiRouteCoordinates: [[String: Double]]) -> [String: Any] {
        let routeCoordinates = locationManager.locations.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        
        guard let firstLocation = locationManager.locations.first,
              let lastLocation = locationManager.locations.last else {
            print("No locations to submit.")
            return [:]
        }
        
        var routeData = [
            "start": [
                "latitude": firstLocation.latitude,
                "longitude": firstLocation.longitude,
                "timestamp": firstLocation.timestamp.formatted(date: .omitted, time: .shortened)
            ],
            "end": [
                "latitude": lastLocation.latitude,
                "longitude": lastLocation.longitude,
                "timestamp": lastLocation.timestamp.formatted(date: .omitted, time: .shortened)
            ],
            "route": routeCoordinates,
            "pois": pois.map { ["name": $0.name, "type": $0.type, "location": ["latitude": $0.location.latitude, "longitude": $0.location.longitude], "notes": $0.notes] },
            "locationName": locationText,
            "Route Type": RouteType,
            "poiRoute": poiRouteCoordinates
        ] as [String : Any]
        
        if let selectedPOI = selectedPOI {
            routeData["selectedPOI"] = selectedPOI
        }
        
        return routeData
    }
    
    
    
    func saveToUserDefaults(data: [String: Any]) {
        // Load existing data or initialize an empty array
        var existingData = UserDefaults.standard.array(forKey: "offlineRoutes") as? [[String: Any]] ?? []
        
        // Append new data
        existingData.append(data)
        
        // Save updated data back to UserDefaults
        UserDefaults.standard.set(existingData, forKey: "offlineRoutes")
        
        print("Route data saved locally!")
    }
    
    func submitOfflineData() {
        guard let offlineData = UserDefaults.standard.array(forKey: "offlineRoutes") as? [[String: Any]] else {
            print("No offline data available.")
            return
        }
        
        // Loop through offline data and submit to Firestore
        for data in offlineData {
            let docRef = db.collection("locations").document() // Create document reference
            
            // Add data to the document
            docRef.setData(data) { error in
                if let error = error {
                    print("Error writing route: \(error.localizedDescription)")
                } else {
                    print("Offline Route successfully submitted to Firestore!")
                    
                    // Remove submitted data from UserDefaults
                    if let index = offlineData.firstIndex(where: { isEqualDictionary($0, data) }) {
                        var updatedData = UserDefaults.standard.array(forKey: "offlineRoutes") as? [[String: Any]] ?? []
                        updatedData.remove(at: index)
                        UserDefaults.standard.set(updatedData, forKey: "offlineRoutes")
                    }
                }
            }
        }
    }
    
    
    func isEqualDictionary(_ dict1: [String: Any], _ dict2: [String: Any]) -> Bool {
        guard dict1.keys.sorted() == dict2.keys.sorted() else { return false }
        
        for key in dict1.keys {
            if let value1 = dict1[key] as? AnyObject, let value2 = dict2[key] as? AnyObject {
                if value1 !== value2 {
                    return false
                }
            } else {
                return false
            }
        }
        
        return true
    }
    
    private func calculateTotalDistanceAndElevation(_ locations: [LocationData]) {
           guard !locations.isEmpty else {
               totalDistance = 0
               totalElevationChange = 0
               return
           }
           
           var distance: CLLocationDistance = 0
           var elevationChange: CLLocationDistance = 0
           
           for i in 0..<(locations.count - 1) {
               let location1 = locations[i]
               let location2 = locations[i + 1]
               
               let coordinate1 = CLLocation(latitude: location1.latitude, longitude: location1.longitude)
               let coordinate2 = CLLocation(latitude: location2.latitude, longitude: location2.longitude)
               
               // Calculate distance between two coordinates
               let segmentDistance = coordinate1.distance(from: coordinate2)
               distance += segmentDistance
               
               // Calculate elevation change (if available)
               let segmentElevationChange = location2.altitude - location1.altitude
               elevationChange += segmentElevationChange
           }
           
           // Update total distance and elevation change
           totalDistance = distance
           totalElevationChange = elevationChange
       }
    
    
    func resetView() {
        locationManager.locations = [] // Clear location data
        pois = [] // Clear POI data
        locationText = "" // Clear location text field
        RouteType = "" // Clear postcode text field
    }
}


struct MapView: UIViewRepresentable {
    let locations: [LocationData]
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.removeOverlays(uiView.overlays)
        
        let overlays = locations.map { MKPolyline(coordinates: [$0.coordinate], count: 1) }
        uiView.addOverlays(overlays)
        
        let center = locations.last?.coordinate ?? MKCoordinateRegion().center
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: center, span: span)
        uiView.setRegion(region, animated: true)
    }
}




extension LocationData {
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}



#Preview {
    ContentView()
}
