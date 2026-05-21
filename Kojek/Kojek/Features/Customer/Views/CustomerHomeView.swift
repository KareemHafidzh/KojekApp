//
//  CustomerHomeView.swift
//  Kojek
//
//  Created by Kareem Abdul Hafidzh on 16/05/26.
//

import SwiftUI

struct CustomerHomeView: View {
    @EnvironmentObject var auth: AuthViewModel
    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        HeaderView()
                        WalletCard()
                        ServiceGrid()
                        PromoCarousel()
                        Spacer(minLength: 100)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Components

struct HeaderView: View {
    @EnvironmentObject var auth: AuthViewModel
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Good Morning,")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text("Kareem Hafidzh")
                    .font(.title3.bold())
                    .foregroundColor(.textColor)
            }
            Spacer()
            HStack(spacing: 10) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 20))
                    .padding(10)
                    .background(Color.inputBackgroundColor)
                    .clipShape(Circle())
                    .shadow(color: Color.black.opacity(0.05), radius: 5)
                
                Button(action: {
                    Task { await auth.signOut() }
                }) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                        .foregroundColor(.red)
                        .padding(10)
                        .background(Color.inputBackgroundColor)
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.05), radius: 5)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct WalletCard: View {
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading) {
                HStack {
                    Image(systemName: "creditcard.fill")
                    Text("Wallet Balance")
                }
                .font(.caption)
                .opacity(0.9)
                
                Text("Rp 1.250.000")
                    .font(.headline.bold())
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primaryColor)
            .foregroundColor(.white)
            
            HStack(spacing: 20) {
                WalletAction(icon: "plus.circle", label: "Top Up")
                WalletAction(icon: "arrow.up.right.circle", label: "Pay")
            }
            .padding(.horizontal)
            .frame(maxHeight: .infinity)
            .background(Color.inputBackgroundColor)
        }
        .frame(height: 80)
        .cornerRadius(16)
        .padding(.horizontal)
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

struct WalletAction: View {
    let icon: String
    let label: String
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundColor(.primaryColor)
            Text(label)
                .font(.caption2)
                .foregroundColor(.textColor)
        }
    }
}

struct ServiceGrid: View {
    let services = [
        ("Ride", "bicycle", Color.blue),
        ("Car", "car.fill", Color.blue),
        ("Food", "mouth.fill", Color.orange),
        ("Send", "box.truck.fill", Color.secondaryColor),
        ("Mart", "basket.fill", Color.red),
        ("Bills", "doc.text.fill", Color.purple),
        ("Health", "heart.fill", Color.pink),
        ("More", "ellipsis.circle.fill", Color.gray)
    ]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 20) {
            ForEach(services, id: \.0) { service in
                // ✅ Wrap only "Ride" in a NavigationLink
                if service.0 == "Ride" {
                    NavigationLink(destination: RideBookingView()) {
                        serviceIcon(service)
                    }
                    .buttonStyle(.plain)
                } else {
                    serviceIcon(service)
                }
            }
        }
        .padding()
        .background(Color.inputBackgroundColor)
        .cornerRadius(20)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func serviceIcon(_ service: (String, String, Color)) -> some View {
        VStack {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(service.2.opacity(0.1))
                    .frame(width: 50, height: 50)
                Image(systemName: service.1)
                    .foregroundColor(service.2)
            }
            Text(service.0)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.textColor)
        }
    }
}

struct PromoCarousel: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Promos for you")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(0..<3) { _ in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(LinearGradient(colors: [.primaryColor.opacity(0.8), .secondaryColor], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 280, height: 150)
                            .overlay(
                                Text("50% Off Your First Ride")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                    .padding(),
                                alignment: .bottomLeading
                            )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerHomeView()
    }
}
