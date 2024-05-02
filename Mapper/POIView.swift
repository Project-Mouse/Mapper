//
//  POIView.swift
//  Mapper
//
//  Created by Imran Razak on 23/04/2024.
//

import SwiftUI
import CoreLocation

struct POI: Hashable, Equatable {
    let name: String
    let type: String
    let location: CLLocationCoordinate2D
    let notes: String

    // Conforming to Equatable
    static func ==(lhs: POI, rhs: POI) -> Bool {
        return lhs.name == rhs.name &&
               lhs.type == rhs.type &&
               lhs.location.latitude == rhs.location.latitude &&
               lhs.location.longitude == rhs.location.longitude &&
               lhs.notes == rhs.notes
    }

    // Conforming to Hashable
    func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(location.latitude)
        hasher.combine(location.longitude)
        hasher.combine(notes)
    }
}



struct POIView: View {
    @Binding var pois: [POI]
     @Binding var showPOIForm: Bool
     @Binding var poiRouteCoordinates: [[String: Double]]
     @Binding var selectedPOI: String
    
    @State private var newPOIName: String = ""
  //  @State private var selectedPOI: String = "Toilet"
    @State private var notes: String = ""
    @State private var selectedLocationIndex: Int? // To store selected location index
    @State private var isSelectingPOILocation: Bool = false
    @State private var isTracing: Bool = false // To track if location tracing is active
   // @State private var poiRouteCoordinates: [[String: Double]] = [] // Store POI route coordinates
    
    @ObservedObject var locationManager = LocationManager()
    
    let interestOptions = ["Toilet", "Landmark", "Car Park", "Public Transport", "Cafe"]
    
    var body: some View {
        NavigationView {
            Form {
                TextField("POI Name", text: $newPOIName)
                
                Picker("Type", selection: $selectedPOI) {
                    ForEach(interestOptions, id: \.self) { option in
                        Text(option)
                    }
                }
                
                HStack {
                    if isTracing {
                        Button("Pause") {
                            locationManager.pauseTracing()
                            isTracing = false
                        }
                    } else {
                        Button("Capture") {
                            locationManager.startTracing()
                            isTracing = true
                        }
                    }
                }
                
                List {
                    ForEach(locationManager.locations.indices, id: \.self) { index in
                        HStack {
                            Text("Latitude: \(locationManager.locations[index].coordinate.latitude), Longitude: \(locationManager.locations[index].coordinate.longitude)")
                            Spacer()
                            if selectedLocationIndex == index {
                                Image(systemName: "checkmark")
                            }
                        }
                        .onTapGesture {
                            isSelectingPOILocation.toggle()
                            selectedLocationIndex = index
                        }
                    }
                }
                
                TextEditor(text: $notes) // Multi-line text input for notes
                    .frame(minHeight: 100) // Set minimum height for notes section
                
                Button("Add POI") {
                    guard let selectedLocationIndex = selectedLocationIndex else {
                        // Handle case where POI location is not selected
                        print("Please select a POI location.")
                        return
                    }
                    
                    let selectedLocation = locationManager.locations[selectedLocationIndex].coordinate // Access the coordinate property of CLLocation object
                    let newPOI = POI(name: newPOIName, type: selectedPOI, location: selectedLocation, notes: notes)
                    pois.append(newPOI) // Add POI object to the list
                    newPOIName = ""
                    notes = ""
                    locationManager.pauseTracing()
                    isTracing = false
                    
                    // Capture the POI route coordinates
                       self.poiRouteCoordinates = locationManager.locations.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
                       self.selectedPOI = selectedPOI
                    
                    // Close the POIView sheet
                    showPOIForm = false
                }
            }
            .navigationTitle("Add POI")
        }
    }
}


