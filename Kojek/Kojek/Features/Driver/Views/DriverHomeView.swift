//
//  DriverHomeView.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 17/05/26.
//

import SwiftUI
import MapKit

struct DriverHomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    @StateObject private var socketService = RideSocketService.shared
    
    @State private var isOnline = false
    @State private var todaysEarnings: Double = 145000
    @State private var totalTrips: Int = 4
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.backgroundColor.ignoresSafeArea()
            
            Map()
                .ignoresSafeArea(edges: .bottom)
                .opacity(isOnline ? 1.0 : 0.4)
                .animation(.easeInOut, value: isOnline)

            VStack(spacing: 0) {
                topNavigationLayer
                Spacer()
                dashboardLayer
            }
            
            // MARK: Incoming Ride Alert
            if let request = socketService.pendingRequest {
                incomingRideSheet(request: request)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(2)
            }
        }
    }
    
    // MARK: - UI Components
    
    private func incomingRideSheet(request: RideRequest) -> some View {
        VStack(spacing: 20) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("New Ride Request")
                        .font(.headline)
                        .foregroundColor(.primaryColor)
                    Text("Incoming ride from \(request.pickupTitle)")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Spacer()
                Text("Rp \(request.fare)")
                    .font(.title3.bold())
                    .foregroundColor(.textColor)
            }
            
            Divider()
            
            VStack(spacing: 16) {
                locationRow(title: "Pickup", address: request.pickupTitle, icon: "smallcircle.filled.circle", color: .blue)
                locationRow(title: "Dropoff", address: request.dropoffTitle, icon: "mappin.and.ellipse", color: .green)
            }
            
            HStack(spacing: 12) {
                Button(action: { socketService.clearRequest() }) {
                    Text("Decline")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.inputBackgroundColor)
                        .cornerRadius(12)
                }
                
                Button(action: {
                    socketService.acceptRide(request: request)
                    withAnimation {
                        totalTrips += 1
                        todaysEarnings += Double(request.fare)
                    }
                }) {
                    Text("Accept Ride")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryColor)
                        .cornerRadius(12)
                }
            }
        }
        .padding(24)
        .background(Color.backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
        .shadow(color: .black.opacity(0.15), radius: 20, y: -10)
        .padding(.horizontal, 12)
        .padding(.bottom, 20)
    }
    
    private func locationRow(title: String, address: String, icon: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                Text(address)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
    
    private var topNavigationLayer: some View {
        HStack {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "person.fill").foregroundColor(.gray))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Driver Partner")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text("Ready to drive?")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.textColor)
                }
            }
            
            Spacer()
            
            Button(action: {
                Task { await auth.signOut() }
            }) {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(.red)
                    .padding(10)
                    .background(Color.inputBackgroundColor)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color.backgroundColor.shadow(color: .black.opacity(0.05), radius: 5, y: 5))
    }
    
    private var dashboardLayer: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                StatCard(
                    title: "Today's Earnings",
                    value: "Rp \(Int(todaysEarnings))",
                    icon: "banknote.fill",
                    color: .green
                )
                StatCard(
                    title: "Total Trips",
                    value: "\(totalTrips)",
                    icon: "car.fill",
                    color: .primaryColor
                )
            }
            
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isOnline.toggle()
                    if isOnline {
                        socketService.connect()
                    } else {
                        socketService.disconnect()
                    }
                }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(isOnline ? Color.red : Color.primaryColor)
                        .frame(height: 64)
                    
                    HStack(spacing: 10) {
                        Image(systemName: isOnline ? "power" : "paperplane.fill")
                        Text(isOnline ? "Go Offline" : "GO ONLINE")
                            .font(.title3)
                            .fontWeight(.black)
                    }
                    .foregroundColor(.white)
                }
            }
            .shadow(color: (isOnline ? Color.red : Color.primaryColor).opacity(0.3), radius: 10, y: 5)
        }
        .padding(20)                          // ← inner padding (content breathes inside the card)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.backgroundColor)
                .shadow(color: .black.opacity(0.1), radius: 20, y: -5)
        )
        .padding(.horizontal, 16)            // ← outer padding (card floats away from screen edges)
        .padding(.bottom, 24)
        .disabled(socketService.pendingRequest != nil) // Disable dashboard interaction when a ride is pending
        .opacity(socketService.pendingRequest != nil ? 0.5 : 1.0)
    }
}

// MARK: - Reusable Components

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.inputBackgroundColor)
        .cornerRadius(16)
    }
}

#Preview {
    DriverHomeView()
        .environmentObject(AuthViewModel())
}
