//
//  RideBookingView.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 17/05/26.
//

import SwiftUI
import MapKit

struct RideBookingView: View {
    @StateObject private var viewModel = RideBookingViewModel()
    @FocusState private var focusedField: RideBookingViewModel.FocusField?
    
    @State private var cameraPosition: MapCameraPosition = .camera(
        MapCamera(centerCoordinate: CLLocationCoordinate2D(latitude: -6.2088, longitude: 106.8456), distance: 50000)
    )
    
    var body: some View {
        ZStack(alignment: .top) {
            
            Map(position: $cameraPosition) {
                if let pickup = viewModel.pickupLocation {
                    Marker("Pickup", coordinate: pickup.coordinate).tint(.blue)
                }
                if let dropoff = viewModel.dropoffLocation {
                    Marker("Dropoff", coordinate: dropoff.coordinate).tint(.green)
                }
                
                if let route = viewModel.route {
                    MapPolyline(route.polyline)
                        .stroke(.blue, lineWidth: 5)
                }
            }
            .ignoresSafeArea()
            .onChange(of: viewModel.route) { route in
                guard let rect = route?.polyline.boundingMapRect else { return }
                withAnimation {
                    cameraPosition = .rect(rect)
                }
            }
            
            VStack(spacing: 16) {
                locationInputCard
                
                if !viewModel.searchResults.isEmpty {
                    searchResultsList
                }
                
                Spacer()
                
                if viewModel.pickupLocation != nil && viewModel.dropoffLocation != nil {
                    bookButton
                }
            }
            .padding()
        }
        .onChange(of: focusedField) { newValue in
            viewModel.activeSearchField = newValue
        }
        .onAppear {
            viewModel.socketService.connect()
        }
    }
    
    // MARK: - Subviews
    
    private var locationInputCard: some View {
        VStack(spacing: 12) {
            // MARK: Pickup Field
            HStack {
                Image(systemName: "smallcircle.filled.circle")
                    .foregroundColor(.blue)
                
                TextField("Current Location", text: Binding(
                    get: {
                        focusedField == .pickup ? viewModel.searchQuery : (viewModel.pickupLocation?.title ?? "")
                    },
                    set: { newValue in
                        if focusedField == .pickup { viewModel.searchQuery = newValue }
                    }
                ))
                .focused($focusedField, equals: .pickup)
                .onChange(of: focusedField) { field in
                    if field == .pickup {
                        viewModel.searchQuery = viewModel.pickupLocation?.title ?? ""
                    }
                }
            }
            
            Divider()
            
            // MARK: Dropoff Field
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(.green)
                
                TextField("Where to?", text: Binding(
                    get: {
                        focusedField == .dropoff ? viewModel.searchQuery : (viewModel.dropoffLocation?.title ?? "")
                    },
                    set: { newValue in
                        if focusedField == .dropoff { viewModel.searchQuery = newValue }
                    }
                ))
                .focused($focusedField, equals: .dropoff)
                .onChange(of: focusedField) { field in
                    if field == .dropoff {
                        viewModel.searchQuery = viewModel.dropoffLocation?.title ?? ""
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var searchResultsList: some View {
        // 1. Wrap the VStack in a ScrollView so it can handle overflow
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.searchResults, id: \.self) { result in
                    Button(action: {
                        viewModel.selectLocation(result)
                        focusedField = nil
                    }) {
                        HStack(spacing: 14) {
                            // Icon
                            ZStack {
                                Circle()
                                    .fill(Color.primaryColor.opacity(0.1))
                                    .frame(width: 38, height: 38)
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.primaryColor)
                                    .font(.system(size: 18))
                            }
                            
                            // Text
                            VStack(alignment: .leading, spacing: 3) {
                                Text(result.title)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                
                                Text(result.subtitle)
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.5))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    if result != viewModel.searchResults.last {
                        Divider()
                            .padding(.leading, 68)
                    }
                }
            }
        }
        .frame(maxHeight: 300)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }
    
    private var bookButton: some View {
        VStack(spacing: 16) {
            if let route = viewModel.route {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Estimated Fare")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(viewModel.formattedFare)
                            .font(.title2.bold())
                            .foregroundColor(.primaryColor)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 6) {
                        Label("\(Int(route.expectedTravelTime / 60)) min", systemImage: "clock")
                        Label(String(format: "%.1f km", route.distance / 1000), systemImage: "road.lanes")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                Divider()
            }
            
            switch viewModel.socketService.rideStatus {
            case .idle:
                Button(action: { viewModel.confirmBooking() }) {
                    Text("Confirm Booking")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primaryColor)
                        .cornerRadius(12)
                }
            case .searching:
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Searching for nearest driver...")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
            case .driverAssigned(let name):
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("\(name) is on the way!")
                            .font(.headline)
                    }
                    Text("Your driver will arrive shortly.")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.12), radius: 20, x: 0, y: -4)
    }
}

#Preview {
    RideBookingView()
}
