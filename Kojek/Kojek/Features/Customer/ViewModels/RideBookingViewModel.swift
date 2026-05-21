//
//  RideBookingViewModel.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 17/05/26.
//

import Foundation
import MapKit
import Combine

@MainActor
class RideBookingViewModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var pickupLocation: KojekLocation?
    @Published var dropoffLocation: KojekLocation?
    @Published var route: MKRoute?
    
    @Published var searchQuery = ""
    @Published var searchResults: [MKLocalSearchCompletion] = []
    
    // Observe the socket service for status updates
    @Published var socketService = RideSocketService.shared
    
    var activeSearchField: FocusField?
    enum FocusField { case pickup, dropoff }
    
    private var completer: MKLocalSearchCompleter
    private var cancellable: AnyCancellable?
    private var statusCancellable: AnyCancellable?
    
    override init() {
        completer = MKLocalSearchCompleter()
        super.init()
        
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
        
        cancellable = $searchQuery
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink { [weak self] query in
                if query.isEmpty {
                    self?.searchResults = []
                } else {
                    self?.completer.queryFragment = query
                }
            }
        
        // Listen to rideStatus changes from RideSocketService
        statusCancellable = socketService.$rideStatus
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
    }
    
    func confirmBooking() {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        
        // Ensure connected before sending
//        socketService.connect()
        
        socketService.sendRideRequest(
            pickup: pickup.title,
            dropoff: dropoff.title,
            fare: estimatedFare
        )
    }
    
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        self.searchResults = completer.results
    }
    
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search failed: \(error.localizedDescription)")
    }
    
    func selectLocation(_ completion: MKLocalSearchCompletion) {
        let targetField = activeSearchField
        let searchRequest = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: searchRequest)
        
        search.start { [weak self] response, error in
            guard let self = self, let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            
            let location = KojekLocation(title: completion.title, subtitle: completion.subtitle, coordinate: coordinate)
            
            if targetField == .pickup {
                self.pickupLocation = location
            } else if targetField == .dropoff {
                self.dropoffLocation = location
            }
            
            self.searchQuery = ""
            self.searchResults = []
            
            if self.pickupLocation != nil && self.dropoffLocation != nil {
                self.fetchRoute()
            }
        }
    }
    
    func fetchRoute() {
        guard let pickup = pickupLocation, let dropoff = dropoffLocation else { return }
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: pickup.coordinate))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dropoff.coordinate))
        request.transportType = .automobile
        request.requestsAlternateRoutes = true  // get multiple options
        
        Task {
            let directions = MKDirections(request: request)
            if let response = try? await directions.calculate() {
                // .routes is already sorted fastest first
                self.route = response.routes.first
            }
        }
    }
    
    var estimatedFare: Int {
        guard let route = route else { return 0 }
        let baseFare = 5_000
        let ratePerHundredMeter = 250          // Rp 2.500/km
        let units = Int(route.distance / 100)
        return max(baseFare + units * ratePerHundredMeter, 8_000) // min fare Rp 8.000
    }

    var formattedFare: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        formatter.locale = Locale(identifier: "id_ID")
        return "Rp \(formatter.string(from: NSNumber(value: estimatedFare)) ?? "0")"
    }
}
