import request from 'supertest';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { createApp } from '../app';
import { seedInitialUsers } from '../services/seedService';
import { TicketModel } from '../models/Ticket';
import { UserModel } from '../models/User';

let mongoServer: MongoMemoryServer;
let app: any;

let customerToken: string;
let customerId: string;
let tech1Token: string;
let tech1Id: string;
let tech2Token: string;
let tech2Id: string;
let adminToken: string;
let adminId: string;

beforeAll(async () => {
  mongoServer = await MongoMemoryServer.create();
  const uri = mongoServer.getUri();
  await mongoose.connect(uri);

  app = createApp();
  await seedInitialUsers();

  // Login as Customer
  const custRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'customer@fsm.local', password: 'Customer123!' });
  customerToken = custRes.body.accessToken;
  customerId = custRes.body.user.id;

  // Login as Technician 1 (Available)
  const tech1Res = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'tech1@fsm.local', password: 'Tech123!' });
  tech1Token = tech1Res.body.accessToken;
  tech1Id = tech1Res.body.user.id;

  // Login as Technician 2 (Unavailable)
  const tech2Res = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'tech2@fsm.local', password: 'Tech123!' });
  tech2Token = tech2Res.body.accessToken;
  tech2Id = tech2Res.body.user.id;

  // Login as Admin
  const adminRes = await request(app)
    .post('/api/v1/auth/login')
    .send({ email: 'admin@fsm.local', password: 'Admin123!' });
  adminToken = adminRes.body.accessToken;
  adminId = adminRes.body.user.id;
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongoServer.stop();
});

describe('1. Authentication & RBAC Matrix Tests', () => {
  it('should authenticate Customer, Technician, and Admin correctly', () => {
    expect(customerToken).toBeDefined();
    expect(tech1Token).toBeDefined();
    expect(adminToken).toBeDefined();
  });

  it('should reject invalid password with 401', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ email: 'admin@fsm.local', password: 'WrongPassword!' });
    expect(res.status).toBe(401);
  });

  it('should reject unauthenticated request with 401', async () => {
    const res = await request(app).get('/api/v1/tickets');
    expect(res.status).toBe(401);
  });

  it('should prevent Technician from creating tickets (403 Forbidden)', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        title: 'Air conditioner failure',
        description: 'Compressor not starting',
        lng: 100.523,
        lat: 13.736,
        address: 'Siam Paragon, Bangkok'
      });
    expect(res.status).toBe(403);
    expect(res.body.error).toBe('FORBIDDEN');
  });

  it('should prevent Customer from assigning tickets (403 Forbidden)', async () => {
    const res = await request(app)
      .patch('/api/v1/tickets/fake-id/assign')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({ technicianId: tech1Id });
    expect(res.status).toBe(403);
  });
});

describe('2. Ticket Creation & Geolocation (GeoJSON Standard)', () => {
  let createdTicket: any;

  it('should allow Customer to create a ticket with GeoJSON Point coordinates', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'HVAC Air Filter Replacement',
        description: 'Office 4th floor AC blowing warm air',
        lng: 100.523186,
        lat: 13.736717,
        address: 'Building B, Rama 4 Road, Bangkok'
      });

    expect(res.status).toBe(201);
    expect(res.body.ticket).toBeDefined();
    expect(res.body.ticket.ticketCode).toMatch(/^TK-\d+-\d+$/);
    expect(res.body.ticket.status).toBe('Pending');
    expect(res.body.ticket.location.type).toBe('Point');
    expect(res.body.ticket.location.coordinates).toEqual([100.523186, 13.736717]);

    createdTicket = res.body.ticket;
  });

  it('should isolate ticket lists based on RBAC scoping', async () => {
    // Customer sees this ticket
    const custRes = await request(app)
      .get('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`);
    expect(custRes.body.tickets.length).toBeGreaterThanOrEqual(1);

    // Technician 1 does not see this ticket yet (not assigned)
    const techRes = await request(app)
      .get('/api/v1/tickets')
      .set('Authorization', `Bearer ${tech1Token}`);
    expect(techRes.body.tickets.some((t: any) => t._id === createdTicket._id)).toBe(false);

    // Admin sees all tickets
    const adminRes = await request(app)
      .get('/api/v1/tickets')
      .set('Authorization', `Bearer ${adminToken}`);
    expect(adminRes.body.tickets.some((t: any) => t._id === createdTicket._id)).toBe(true);
  });
});

describe('3. Dispatcher Assignment & Availability Rules', () => {
  let ticketId: string;

  beforeEach(async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Chiller Leakage',
        description: 'Urgent water dripping from unit',
        lng: 100.530000,
        lat: 13.740000,
        address: 'CentralWorld, Bangkok'
      });
    ticketId = res.body.ticket._id;
  });

  it('should reject assignment if technician is unavailable', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech2Id }); // Tech 2 has isAvailable: false

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('TECHNICIAN_NOT_AVAILABLE');
  });

  it('should successfully assign available technician and transition to Assigned', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id }); // Tech 1 has isAvailable: true

    expect(res.status).toBe(200);
    expect(res.body.ticket.status).toBe('Assigned');
    expect(res.body.ticket.assignedTechnician).toBe(tech1Id);
  });
});

describe('4. Ticket State Machine & Geofence Lock (<= 200m)', () => {
  let ticketId: string;
  const ticketTargetCoord = [100.523186, 13.736717]; // Siam Area

  beforeEach(async () => {
    // 1. Create ticket
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Server Room AC Check',
        description: 'Temperature spike alert',
        lng: ticketTargetCoord[0],
        lat: ticketTargetCoord[1],
        address: 'Data Center Site 1'
      });
    ticketId = createRes.body.ticket._id;

    // 2. Assign to Tech 1
    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id });
  });

  it('should prohibit illegal state skip (e.g. Assigned -> InProgress directly)', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        nextStatus: 'InProgress',
        currentLng: ticketTargetCoord[0],
        currentLat: ticketTargetCoord[1]
      });

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('INVALID_TRANSITION');
  });

  it('should allow Assigned -> EnRoute', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    expect(res.status).toBe(200);
    expect(res.body.ticket.status).toBe('EnRoute');
  });

  it('should BLOCK InProgress if technician is outside 200m geofence (Geofence Breach)', async () => {
    // Transition to EnRoute first
    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    // Technician is ~1.5 km away (coords: [100.535000, 13.745000])
    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        nextStatus: 'InProgress',
        currentLng: 100.535000,
        currentLat: 13.745000
      });

    expect(res.status).toBe(422);
    expect(res.body.error).toBe('GEOFENCE_BREACH');
    expect(res.body.distanceMeters).toBeGreaterThan(200);
  });

  it('should ALLOW InProgress if technician is within 200m geofence', async () => {
    // Transition to EnRoute first
    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    // Technician is ~25 meters away from [100.523186, 13.736717]
    const nearLng = 100.523286;
    const nearLat = 13.736817;

    const res = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        nextStatus: 'InProgress',
        currentLng: nearLng,
        currentLat: nearLat
      });

    expect(res.status).toBe(200);
    expect(res.body.ticket.status).toBe('InProgress');
    expect(res.body.verifiedDistanceMeters).toBeLessThanOrEqual(200);
  });
});

describe('5. Items & Parts Addition during InProgress', () => {
  let inProgressTicketId: string;

  beforeEach(async () => {
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Condenser fan motor replacement',
        description: 'Loud grinding sound',
        lng: 100.520000,
        lat: 13.730000,
        address: 'Sukhumvit Soi 11'
      });
    inProgressTicketId = createRes.body.ticket._id;

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id });

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        nextStatus: 'InProgress',
        currentLng: 100.520000,
        currentLat: 13.730000
      });
  });

  it('should push spare parts into items embedded array', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/items`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        itemName: 'Capacitor 45uF 450V',
        quantity: 2,
        unitPrice: 450
      });

    expect(res.status).toBe(200);
    expect(res.body.items.length).toBe(1);
    expect(res.body.items[0].itemName).toBe('Capacitor 45uF 450V');
    expect(res.body.items[0].quantity).toBe(2);
    expect(res.body.items[0].unitPrice).toBe(450);
  });

  it('should reject invalid item parameters (quantity < 1)', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/items`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        itemName: 'Wire harness',
        quantity: 0,
        unitPrice: 100
      });

    expect(res.status).toBe(400);
  });
});

describe('6. Evidence & Sign-off Invariants (Before >= 1, After >= 1)', () => {
  let inProgressTicketId: string;

  beforeEach(async () => {
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Filter & Coil Cleaning',
        description: 'Routine maintenance',
        lng: 100.520000,
        lat: 13.730000,
        address: 'Silom Complex'
      });
    inProgressTicketId = createRes.body.ticket._id;

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id });

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    await request(app)
      .patch(`/api/v1/tickets/${inProgressTicketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        nextStatus: 'InProgress',
        currentLng: 100.520000,
        currentLat: 13.730000
      });
  });

  it('should REJECT sign-off when Before photo is missing', async () => {
    // Add only After photo
    await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        photoType: 'After',
        fileUrl: '/uploads/after-clean.jpg'
      });

    const res = await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/sign-off`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ signatureDataUrl: 'data:image/png;base64,sample-signature-base64' });

    expect(res.status).toBe(422);
    expect(res.body.error).toBe('EVIDENCE_INCOMPLETE');
    expect(res.body.current.before).toBe(0);
  });

  it('should REJECT sign-off when After photo is missing', async () => {
    // Add only Before photo
    await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        photoType: 'Before',
        fileUrl: '/uploads/before-dusty.jpg'
      });

    const res = await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/sign-off`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ signatureDataUrl: 'data:image/png;base64,sample-signature-base64' });

    expect(res.status).toBe(422);
    expect(res.body.error).toBe('EVIDENCE_INCOMPLETE');
    expect(res.body.current.after).toBe(0);
  });

  it('should ALLOW sign-off when both Before >= 1 and After >= 1 photos and signature exist', async () => {
    // 1. Upload Before Photo
    await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        photoType: 'Before',
        fileUrl: '/uploads/before-dusty.jpg'
      });

    // 2. Upload After Photo
    await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({
        photoType: 'After',
        fileUrl: '/uploads/after-clean.jpg'
      });

    // 3. Sign-off with customer signature
    const res = await request(app)
      .post(`/api/v1/tickets/${inProgressTicketId}/sign-off`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ signatureDataUrl: 'data:image/png;base64,mockSignatureData===' });

    expect(res.status).toBe(200);
    expect(res.body.ticket.status).toBe('Completed');
    expect(res.body.ticket.customerSignatureUrl).toBe('data:image/png;base64,mockSignatureData===');
    expect(res.body.ticket.closedAt).toBeDefined();
  });
});

describe('7. Cancellation Rules', () => {
  it('should allow cancellation from Pending', async () => {
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Cancel test ticket',
        description: 'Customer cancels early',
        lng: 100.50,
        lat: 13.70,
        address: 'Bangkok'
      });
    const ticketId = createRes.body.ticket._id;

    const cancelRes = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nextStatus: 'Cancelled' });

    expect(cancelRes.status).toBe(200);
    expect(cancelRes.body.ticket.status).toBe('Cancelled');
  });

  it('should reject cancellation from InProgress status', async () => {
    // Create and move to InProgress
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Cancel fail test',
        description: 'Testing cancel guard',
        lng: 100.523186,
        lat: 13.736717,
        address: 'Bangkok'
      });
    const ticketId = createRes.body.ticket._id;

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id });

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'InProgress', currentLng: 100.523186, currentLat: 13.736717 });

    const cancelRes = await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ nextStatus: 'Cancelled' });

    expect(cancelRes.status).toBe(400);
    expect(cancelRes.body.error).toBe('INVALID_TRANSITION');
  });
});

describe('8. Ticket Detail & Validation Edge Cases', () => {
  let sampleTicketId: string;

  beforeAll(async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Inspection Ticket',
        description: 'Detail verification',
        lng: 100.51,
        lat: 13.72,
        address: 'Bangkok'
      });
    sampleTicketId = res.body.ticket._id;
  });

  it('should get ticket by ID for owner customer', async () => {
    const res = await request(app)
      .get(`/api/v1/tickets/${sampleTicketId}`)
      .set('Authorization', `Bearer ${customerToken}`);
    expect(res.status).toBe(200);
    expect(res.body.ticket._id).toBe(sampleTicketId);
  });

  it('should return 404 for non-existent ticket ID', async () => {
    const fakeId = new mongoose.Types.ObjectId();
    const res = await request(app)
      .get(`/api/v1/tickets/${fakeId}`)
      .set('Authorization', `Bearer ${adminToken}`);
    expect(res.status).toBe(404);
  });

  it('should reject ticket creation with missing fields', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({ title: 'Incomplete' });
    expect(res.status).toBe(400);
  });

  it('should reject ticket creation with invalid coordinates', async () => {
    const res = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Bad coords',
        description: 'coords test',
        lng: 'invalid-lng',
        lat: 'invalid-lat',
        address: 'Bangkok'
      });
    expect(res.status).toBe(400);
  });

  it('should reject status update without nextStatus', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${sampleTicketId}/status`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('should reject assignTicket without technicianId', async () => {
    const res = await request(app)
      .patch(`/api/v1/tickets/${sampleTicketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({});
    expect(res.status).toBe(400);
  });

  it('should reject sign-off on ticket that is not InProgress', async () => {
    const res = await request(app)
      .post(`/api/v1/tickets/${sampleTicketId}/sign-off`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ signatureDataUrl: 'data:image/png;base64,test' });
    expect(res.status).toBe(400);
    expect(res.body.error).toBe('INVALID_STATUS');
  });

  it('should reject sign-off without signature', async () => {
    // Create ticket in InProgress with before/after photos
    const createRes = await request(app)
      .post('/api/v1/tickets')
      .set('Authorization', `Bearer ${customerToken}`)
      .send({
        title: 'Sign-off missing sig test',
        description: 'Testing signature requirement',
        lng: 100.523186,
        lat: 13.736717,
        address: 'Bangkok'
      });
    const ticketId = createRes.body.ticket._id;

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/assign`)
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ technicianId: tech1Id });

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'EnRoute' });

    await request(app)
      .patch(`/api/v1/tickets/${ticketId}/status`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ nextStatus: 'InProgress', currentLng: 100.523186, currentLat: 13.736717 });

    await request(app)
      .post(`/api/v1/tickets/${ticketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ photoType: 'Before', fileUrl: '/uploads/before.jpg' });

    await request(app)
      .post(`/api/v1/tickets/${ticketId}/attachments`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({ photoType: 'After', fileUrl: '/uploads/after.jpg' });

    const res = await request(app)
      .post(`/api/v1/tickets/${ticketId}/sign-off`)
      .set('Authorization', `Bearer ${tech1Token}`)
      .send({}); // Missing signature

    expect(res.status).toBe(400);
    expect(res.body.error).toBe('BAD_REQUEST');
  });
});
