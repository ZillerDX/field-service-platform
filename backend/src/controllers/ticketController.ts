import { Response } from 'express';
import { AuthenticatedRequest } from '../middleware/auth';
import { TicketModel, ITicket, TicketStatus } from '../models/Ticket';
import { UserModel } from '../models/User';
import { isWithinGeofence, calculateDistanceMeters } from '../utils/geo';
import { config } from '../config';

export async function createTicket(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { title, description, lng, lat, address, customerId } = req.body;

    if (!title || !description || lng === undefined || lat === undefined || !address) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Title, description, lng, lat, and address are required'
      });
      return;
    }

    const numLng = parseFloat(lng);
    const numLat = parseFloat(lat);

    if (isNaN(numLng) || isNaN(numLat)) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Coordinates (lng, lat) must be valid numbers'
      });
      return;
    }

    // Role check: If Customer, always own ID. If Admin, can assign to specified customer or self.
    let targetCustomerId = req.user!._id;
    if (req.user!.role === 'Admin' && customerId) {
      targetCustomerId = customerId;
    }

    // Auto-generate ticket code: TK-2026-XXXX
    const uniqueSuffix = `${Date.now().toString().slice(-6)}${Math.floor(1000 + Math.random() * 9000)}`;
    const ticketCode = `TK-2026-${uniqueSuffix}`;

    const ticket = await TicketModel.create({
      ticketCode,
      customer: targetCustomerId,
      title,
      description,
      status: 'Pending',
      location: {
        type: 'Point',
        coordinates: [numLng, numLat],
        address
      },
      items: [],
      attachments: []
    });

    res.status(201).json({
      message: 'Service ticket created successfully',
      ticket
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to create ticket'
    });
  }
}

export async function getTickets(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { status, page = 1, limit = 20 } = req.query;
    const filter: any = {};

    // RBAC Scoping
    if (req.user!.role === 'Customer') {
      filter.customer = req.user!._id;
    } else if (req.user!.role === 'Technician') {
      filter.assignedTechnician = req.user!._id;
    }
    // Admin sees all

    if (status) {
      filter.status = status;
    }

    const skip = (Number(page) - 1) * Number(limit);
    const tickets = await TicketModel.find(filter)
      .populate('customer', 'fullName email phoneNumber')
      .populate('assignedTechnician', 'fullName email phoneNumber technicianProfile')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(Number(limit));

    const total = await TicketModel.countDocuments(filter);

    res.status(200).json({
      tickets,
      pagination: {
        page: Number(page),
        limit: Number(limit),
        total,
        pages: Math.ceil(total / Number(limit))
      }
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to fetch tickets'
    });
  }
}

export async function getTicketById(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const ticket = await TicketModel.findById(id)
      .populate('customer', 'fullName email phoneNumber')
      .populate('assignedTechnician', 'fullName email phoneNumber technicianProfile');

    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    // Role-based visibility validation
    if (req.user!.role === 'Customer' && ticket.customer._id.toString() !== req.user!._id.toString()) {
      res.status(403).json({ error: 'FORBIDDEN', message: 'Access denied to this ticket' });
      return;
    }

    if (
      req.user!.role === 'Technician' &&
      (!ticket.assignedTechnician ||
        ticket.assignedTechnician._id.toString() !== req.user!._id.toString())
    ) {
      res.status(403).json({ error: 'FORBIDDEN', message: 'Access denied to this ticket' });
      return;
    }

    res.status(200).json({ ticket });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to fetch ticket'
    });
  }
}

export async function assignTicket(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { technicianId } = req.body;

    if (!technicianId) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Technician ID is required'
      });
      return;
    }

    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    if (ticket.status !== 'Pending' && ticket.status !== 'Assigned') {
      res.status(400).json({
        error: 'INVALID_STATUS_TRANSITION',
        message: `Cannot assign ticket currently in status '${ticket.status}'`
      });
      return;
    }

    const tech = await UserModel.findById(technicianId);
    if (!tech || tech.role !== 'Technician' || !tech.isActive) {
      res.status(400).json({
        error: 'INVALID_TECHNICIAN',
        message: 'Technician does not exist or is inactive'
      });
      return;
    }

    // Verify technician availability
    if (tech.technicianProfile?.isAvailable === false) {
      res.status(400).json({
        error: 'TECHNICIAN_NOT_AVAILABLE',
        message: `Technician '${tech.fullName}' is currently unavailable`
      });
      return;
    }

    ticket.assignedTechnician = tech._id;
    ticket.status = 'Assigned';
    await ticket.save();

    res.status(200).json({
      message: 'Technician assigned successfully',
      ticket
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to assign technician'
    });
  }
}

export async function updateTicketStatus(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { nextStatus, currentLng, currentLat } = req.body as {
      nextStatus: TicketStatus;
      currentLng?: number;
      currentLat?: number;
    };

    if (!nextStatus) {
      res.status(400).json({ error: 'BAD_REQUEST', message: 'nextStatus is required' });
      return;
    }

    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    // Role check: Technician can only update their own assigned ticket
    if (req.user!.role === 'Technician') {
      if (
        !ticket.assignedTechnician ||
        ticket.assignedTechnician.toString() !== req.user!._id.toString()
      ) {
        res.status(403).json({ error: 'FORBIDDEN', message: 'You are not assigned to this ticket' });
        return;
      }
    }

    const currentStatus = ticket.status;

    // Strict State Machine Transitions
    if (nextStatus === 'EnRoute') {
      if (currentStatus !== 'Assigned') {
        res.status(400).json({
          error: 'INVALID_TRANSITION',
          message: `Cannot transition to 'EnRoute' from '${currentStatus}'. Expected 'Assigned'.`
        });
        return;
      }
      ticket.status = 'EnRoute';
      await ticket.save();
      res.status(200).json({
        message: 'Status updated to EnRoute. Customer notified.',
        ticket
      });
      return;
    }

    if (nextStatus === 'InProgress') {
      if (currentStatus !== 'EnRoute') {
        res.status(400).json({
          error: 'INVALID_TRANSITION',
          message: `Cannot transition to 'InProgress' from '${currentStatus}'. Expected 'EnRoute'.`
        });
        return;
      }

      // Geofence Lock Verification
      if (currentLng === undefined || currentLat === undefined) {
        res.status(400).json({
          error: 'MISSING_GPS_COORDINATES',
          message: 'currentLng and currentLat are required to verify geofence for InProgress'
        });
        return;
      }

      const techCoord: [number, number] = [Number(currentLng), Number(currentLat)];
      const ticketCoord: [number, number] = ticket.location.coordinates;

      const { isWithin, distanceMeters } = isWithinGeofence(
        techCoord,
        ticketCoord,
        config.geofenceRadiusMeters
      );

      if (!isWithin) {
        res.status(422).json({
          error: 'GEOFENCE_BREACH',
          message: `Technician is outside the allowed ${config.geofenceRadiusMeters}m geofence. Current distance: ${distanceMeters}m.`,
          distanceMeters,
          allowedRadiusMeters: config.geofenceRadiusMeters
        });
        return;
      }

      ticket.status = 'InProgress';
      await ticket.save();

      res.status(200).json({
        message: `Geofence verified (${distanceMeters}m <= ${config.geofenceRadiusMeters}m). Status updated to InProgress.`,
        ticket,
        verifiedDistanceMeters: distanceMeters
      });
      return;
    }

    if (nextStatus === 'Cancelled') {
      if (currentStatus !== 'Pending' && currentStatus !== 'Assigned') {
        res.status(400).json({
          error: 'INVALID_TRANSITION',
          message: `Cannot cancel ticket from '${currentStatus}'. Cancellation is only allowed from 'Pending' or 'Assigned'.`
        });
        return;
      }
      ticket.status = 'Cancelled';
      await ticket.save();
      res.status(200).json({ message: 'Ticket cancelled successfully', ticket });
      return;
    }

    if (nextStatus === 'Completed') {
      res.status(400).json({
        error: 'SIGN_OFF_REQUIRED',
        message: "Status 'Completed' must be closed via the /sign-off endpoint with Before/After evidence and customer signature."
      });
      return;
    }

    res.status(400).json({
      error: 'INVALID_TRANSITION',
      message: `Invalid status transition from '${currentStatus}' to '${nextStatus}'.`
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to update ticket status'
    });
  }
}

export async function addTicketItem(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { itemName, quantity, unitPrice } = req.body;

    if (!itemName || quantity === undefined || unitPrice === undefined) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'itemName, quantity, and unitPrice are required'
      });
      return;
    }

    const numQty = Number(quantity);
    const numPrice = Number(unitPrice);

    if (numQty < 1 || numPrice < 0) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Quantity must be >= 1 and unitPrice must be >= 0'
      });
      return;
    }

    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    if (ticket.status !== 'InProgress') {
      res.status(400).json({
        error: 'INVALID_STATUS',
        message: 'Items can only be added while ticket is InProgress'
      });
      return;
    }

    ticket.items.push({
      itemName: itemName.trim(),
      quantity: numQty,
      unitPrice: numPrice
    });

    await ticket.save();

    res.status(200).json({
      message: 'Item added successfully',
      items: ticket.items
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to add item'
    });
  }
}

export async function removeTicketItem(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id, itemId } = req.params;
    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }
    if (ticket.status !== 'InProgress') {
      res.status(400).json({
        error: 'INVALID_STATUS',
        message: 'Items can only be removed while ticket is InProgress'
      });
      return;
    }
    ticket.items = ticket.items.filter((item: any) => item._id.toString() !== itemId);
    await ticket.save();
    res.status(200).json({
      message: 'Item removed successfully',
      items: ticket.items
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to remove item'
    });
  }
}

export async function addAttachment(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { photoType, fileUrl } = req.body;

    if (!photoType || !['Before', 'After', 'SiteReport'].includes(photoType)) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: "photoType must be 'Before', 'After', or 'SiteReport'"
      });
      return;
    }

    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    // Use uploaded file path or provided fileUrl
    const url = req.file ? `/uploads/${req.file.filename}` : fileUrl;
    if (!url) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Either an image file or a valid fileUrl is required'
      });
      return;
    }

    ticket.attachments.push({
      photoType,
      fileUrl: url,
      uploadedBy: req.user!._id,
      uploadedAt: new Date()
    });

    await ticket.save();

    res.status(200).json({
      message: 'Attachment uploaded successfully',
      attachments: ticket.attachments
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to upload attachment'
    });
  }
}

export async function signOffTicket(req: AuthenticatedRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { signatureDataUrl } = req.body;

    const ticket = await TicketModel.findById(id);
    if (!ticket) {
      res.status(404).json({ error: 'NOT_FOUND', message: 'Ticket not found' });
      return;
    }

    if (ticket.status !== 'InProgress') {
      res.status(400).json({
        error: 'INVALID_STATUS',
        message: `Cannot sign off ticket in status '${ticket.status}'. Must be 'InProgress'.`
      });
      return;
    }

    // Strict Invariant: Before photo >= 1 AND After photo >= 1
    const beforeCount = ticket.attachments.filter((a) => a.photoType === 'Before').length;
    const afterCount = ticket.attachments.filter((a) => a.photoType === 'After').length;

    if (beforeCount < 1 || afterCount < 1) {
      res.status(422).json({
        error: 'EVIDENCE_INCOMPLETE',
        message: `Sign-off requires at least 1 'Before' photo and 1 'After' photo. Current count: Before=${beforeCount}, After=${afterCount}`,
        required: { before: 1, after: 1 },
        current: { before: beforeCount, after: afterCount }
      });
      return;
    }

    let signatureUrl = '';
    if (req.file) {
      signatureUrl = `/uploads/${req.file.filename}`;
    } else if (signatureDataUrl) {
      signatureUrl = signatureDataUrl; // Data URL or S3 URL
    } else {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Customer signature image is required for sign-off'
      });
      return;
    }

    ticket.customerSignatureUrl = signatureUrl;
    ticket.status = 'Completed';
    ticket.closedAt = new Date();
    await ticket.save();

    res.status(200).json({
      message: 'Ticket successfully signed off and completed',
      ticket
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to sign off ticket'
    });
  }
}
