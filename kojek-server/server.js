const express = require('express');
const http = require('http');
const { Server } = require("socket.io");

const app = express();
const server = http.createServer(app);
const io = new Server(server);

// Triggered every time an iOS simulator connects
io.on('connection', (socket) => {
    console.log('✅ A device connected. Socket ID:', socket.id);

    // --------------------------------------------------------
    // PHASE 2: MATCHING (Customer to Server to Driver)
    // --------------------------------------------------------
    socket.on('request_ride', (rideData) => {
        console.log('\n🚕 [NEW RIDE] Customer requested a ride:', rideData);
        
        // Broadcast the ride to all other connected devices (Drivers)
        socket.broadcast.emit('incoming_ride', rideData);
        console.log('📢 Broadcasted ride to online drivers.');
    });

    // --------------------------------------------------------
    // PHASE 3 & 4: ACCEPTANCE (Driver to Server to Customer)
    // --------------------------------------------------------
    socket.on('accept_ride', () => {
        console.log('\n🤝 [RIDE ACCEPTED] A driver accepted the ride!');
        
        // Tell the customer their ride was accepted
        socket.broadcast.emit('ride_accepted');
    });

    // --------------------------------------------------------
    // DISCONNECTION
    // --------------------------------------------------------
    socket.on('disconnect', () => {
        console.log('❌ Device disconnected. Socket ID:', socket.id);
    });
});

// Start the server
const PORT = 3000;
server.listen(PORT, () => {
    console.log(`🚀 Kojek Server running natively on http://localhost:${PORT}`);
});