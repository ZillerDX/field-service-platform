import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { login, getMe, refreshToken } from '../controllers/authController';
import {
  createTicket,
  getTickets,
  getTicketById,
  assignTicket,
  updateTicketStatus,
  addTicketItem,
  removeTicketItem,
  addAttachment,
  signOffTicket
} from '../controllers/ticketController';
import { createTechnician, getTechnicians } from '../controllers/technicianController';
import { authenticateToken, requireRole } from '../middleware/auth';
import { config } from '../config';

const router = Router();

// Ensure upload directory exists
const uploadDir = path.resolve(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => {
    cb(null, uploadDir);
  },
  filename: (_req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    cb(null, `${uniqueSuffix}${path.extname(file.originalname)}`);
  }
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 } // 10MB
});

// ==========================================
// 1. Auth Endpoints
// ==========================================
router.post('/auth/login', login);
router.post('/auth/refresh', refreshToken);
router.get('/auth/me', authenticateToken, getMe);

// ==========================================
// 2. Ticket Endpoints (RBAC protected)
// ==========================================

// Create Ticket: Customer or Admin
router.post('/tickets', authenticateToken, requireRole(['Customer', 'Admin']), createTicket);

// List Tickets: All roles (Internally filtered by role)
router.get('/tickets', authenticateToken, getTickets);

// Get Ticket Detail
router.get('/tickets/:id', authenticateToken, getTicketById);

// Assign Ticket: Admin only
router.patch('/tickets/:id/assign', authenticateToken, requireRole(['Admin']), assignTicket);

// Update Status: Technician or Admin (With Geofence Lock)
router.patch(
  '/tickets/:id/status',
  authenticateToken,
  requireRole(['Technician', 'Admin']),
  updateTicketStatus
);

// Add Parts/Items: Technician or Admin (Only during InProgress)
router.post(
  '/tickets/:id/items',
  authenticateToken,
  requireRole(['Technician', 'Admin']),
  addTicketItem
);

// Remove Parts/Items: Technician or Admin (Only during InProgress)
router.delete(
  '/tickets/:id/items/:itemId',
  authenticateToken,
  requireRole(['Technician', 'Admin']),
  removeTicketItem
);

// Upload Evidence Attachment: Technician or Admin
router.post(
  '/tickets/:id/attachments',
  authenticateToken,
  requireRole(['Technician', 'Admin']),
  upload.single('photo'),
  addAttachment
);

// Sign-off Ticket: Technician (Closes ticket to Completed with signature)
router.post(
  '/tickets/:id/sign-off',
  authenticateToken,
  requireRole(['Technician']),
  upload.single('signatureImage'),
  signOffTicket
);

// ==========================================
// 3. Technician Management Endpoints (Admin)
// ==========================================
router.post('/technicians', authenticateToken, requireRole(['Admin']), createTechnician);
router.get('/technicians', authenticateToken, requireRole(['Admin']), getTechnicians);

export default router;
