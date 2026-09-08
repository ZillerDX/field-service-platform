import http from 'http';
import mongoose from 'mongoose';
import { Server as SocketIOServer } from 'socket.io';
import { createApp } from './app';
import { config } from './config';
import { seedInitialUsers } from './services/seedService';

async function startServer() {
  const app = createApp();
  const server = http.createServer(app);

  // Setup Realtime Socket.io
  const io = new SocketIOServer(server, {
    cors: { origin: '*', methods: ['GET', 'POST', 'PATCH'] }
  });

  io.on('connection', (socket) => {
    console.log(`🔌 Socket connected: ${socket.id}`);

    // Join room for specific ticket updates
    socket.on('join_ticket', (ticketId: string) => {
      socket.join(`ticket:${ticketId}`);
      console.log(`Socket ${socket.id} joined room ticket:${ticketId}`);
    });

    // Technician live location broadcast
    socket.on('technician_location_update', (data: { technicianId: string; lng: number; lat: number }) => {
      io.emit('technician_moved', data);
    });

    socket.on('disconnect', () => {
      console.log(`Socket disconnected: ${socket.id}`);
    });
  });

  // Connect to MongoDB
  try {
    console.log(`Connecting to MongoDB at: ${config.mongoUri}`);
    await mongoose.connect(config.mongoUri);
    console.log('MongoDB connection established successfully.');

    // Seed default users for testing
    await seedInitialUsers();

    server.listen(config.port, () => {
      console.log(`🚀 Field Service API Server is running on port ${config.port}`);
      console.log(`👉 Live Local API: http://localhost:${config.port}/api/v1`);
      console.log(`👉 Health Check: http://localhost:${config.port}/health`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
}

if (require.main === module) {
  startServer();
}
