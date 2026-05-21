# 🛵 Kojek - Real-Time Ride-Hailing Platform

A full-stack iOS and Node.js application demonstrating real-time bidirectional communication using WebSockets. This project mimics the core functionality of a ride-hailing marketplace (like Gojek or Uber), allowing a Customer app and a Driver app to communicate seamlessly with sub-second latency.

## 🏗 Architecture Overview

This project is built using a decoupled **Monorepo** structure:

### 1. iOS Client (`/Kojek`)
* **Language/UI:** Swift & SwiftUI
* **Architecture:** Strict MVVM (Model-View-ViewModel)
* **Networking:** `Socket.IO-Client-Swift`
* **Features:** * Clean Separation of Concerns (`Core` engine vs `Features` modules).
  * Real-time UI state updates using Combine (`@Published`).
  * MapKit integration for geographic data handling.

### 2. Node.js Backend (`/kojek-server`)
* **Environment:** Node.js
* **Framework:** Express
* **Real-Time Engine:** Socket.IO
* **Features:**
  * Acts as the "Traffic Cop" routing real-time requests.
  * Handles concurrent WebSocket connections for multiple devices.
  * Event-driven architecture (`request_ride`, `incoming_ride`, `accept_ride`).

---

## 🚀 Data Flow & Lifecycle

1. **Connection Phase:** Drivers toggle their status to "Online", opening a persistent WebSocket connection to the server.
2. **Matching Phase:** Customers define a pickup/dropoff and emit a `request_ride` payload.
3. **Dispatch Phase:** The Node.js server receives the request and broadcasts it to available driver clients.
4. **Acceptance Phase:** A driver accepts the ping, emitting an `accept_ride` event back to the server, which then notifies the specific customer to close the loop.

---

## 💻 How to Run Locally

### Prerequisites
* Xcode 15+
* Node.js (v18+)
* Two iOS Simulators (to test Customer/Driver interaction)

### Start the Backend
1. Open terminal and navigate to the server folder: `cd kojek-server`
2. Install dependencies: `npm install`
3. Start the server: `node server.js`
4. Ensure it logs: `🚀 Kojek Server running natively on http://localhost:3000`

### Start the iOS Clients
1. Open `Kojek/Kojek.xcodeproj` in Xcode.
2. Allow Swift Package Manager to resolve the `Socket.IO` dependency.
3. Select an iOS Simulator (e.g., iPhone 15) and press `Cmd + R` to run the Driver view.
4. Select a *different* iOS Simulator (e.g., iPhone 15 Pro) and press `Cmd + R` to run the Customer view. 
5. Test the real-time loop!
