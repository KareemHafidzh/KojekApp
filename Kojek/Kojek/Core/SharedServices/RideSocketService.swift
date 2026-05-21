//
//  RideSocketService.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 20/05/26.
//

import Foundation
import SocketIO
import Combine

// MARK: - Data Transfer Object
struct RideRequest: Identifiable {
    let id = UUID()
    let pickupTitle: String
    let dropoffTitle: String
    let distanceMeters: Double
    let durationSeconds: Double
    let fare: Int
}

// MARK: - Ride Status
enum RideStatus {
    case idle
    case searching
    case driverAssigned(driverName: String)
}

// MARK: - Real-Time Network Bridge
@MainActor
class RideSocketService: ObservableObject {
    static let shared = RideSocketService()

    private var manager: SocketManager!
    private var socket: SocketIOClient!

    // Published states for the UI to react to
    @Published var pendingRequest: RideRequest?
    @Published var isConnected = false
    @Published var rideStatus: RideStatus = .idle

    private init() {
        // Points to your local Mac (Node.js server)
        let url = URL(string: "http://localhost:3000")!
        manager = SocketManager(socketURL: url, config: [.log(false), .compress])
        socket = manager.defaultSocket

        setupEventHandlers()
    }

    // MARK: - Connection Management
    
    func connect() {
        socket.connect()
    }
    
    func disconnect() {
        socket.disconnect()
        clearRequest()
        rideStatus = .idle
    }

    // MARK: - Event Listeners (Incoming)
    
    private func setupEventHandlers() {
        // Triggered when successfully connected to Node.js
        socket.on(clientEvent: .connect) { [weak self] _, _ in
            self?.isConnected = true
            print("🟢 WebSocket Connected")
        }
        
        socket.on(clientEvent: .disconnect) { [weak self] _, _ in
            self?.isConnected = false
            print("🔴 WebSocket Disconnected")
        }

        // Triggered when the server blasts a new ride to drivers
        socket.on("incoming_ride") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let pickup = dict["pickup"] as? String,
                  let dropoff = dict["dropoff"] as? String,
                  let fare = dict["fare"] as? Int else { return }

            self.pendingRequest = RideRequest(
                pickupTitle: pickup,
                dropoffTitle: dropoff,
                distanceMeters: 5000, // Placeholder for demo
                durationSeconds: 900, // Placeholder for demo
                fare: fare
            )
        }
        
        // Triggered when the server tells the Customer a driver accepted
        socket.on("ride_accepted") { [weak self] data, _ in
            guard let self = self,
                  let dict = data.first as? [String: Any],
                  let driverName = dict["driver_name"] as? String else { return }
            
            self.rideStatus = .driverAssigned(driverName: driverName)
            print("🚖 Ride accepted by \(driverName)")
        }
        
        //Catch the acceptance from Node.js
        socket.on("ride_accepted") { [weak self] _, _ in
            print("✅ Driver accepted the ride!")
            
            // This triggers your UI's green success card
            self?.rideStatus = .driverAssigned(driverName: "Driver Partner")
        }
    }

    // MARK: - Event Emitters (Outgoing)
    
    // Triggered by the Customer tapping "Confirm Booking"
    func sendRideRequest(pickup: String, dropoff: String, fare: Int) {
        let rideData: [String: Any] = [
            "pickup": pickup,
            "dropoff": dropoff,
            "fare": fare
        ]
        
        rideStatus = .searching
        socket.emit("request_ride", rideData)
        print("📤 Sent ride request to server")
    }
    
    // Triggered by the Driver tapping "Accept Ride"
    func acceptRide(request: RideRequest) {
        let data: [String: Any] = [
            "ride_id": request.id.uuidString,
            "driver_name": "Kareem (Driver)" // Mock name for now
        ]
        
        socket.emit("accept_ride", data)
        self.pendingRequest = nil
        print("🤝 Accepted ride request")
    }

    func clearRequest() {
        pendingRequest = nil
    }
}
