import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { UserModel } from '../models/User';
import { TicketModel } from '../models/Ticket';

export async function createTechnician(req: Request, res: Response): Promise<void> {
  try {
    const { fullName, username, password, phoneNumber, skillCategory } = req.body;

    if (!fullName || !username || !password) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'fullName, username, and password are required'
      });
      return;
    }

    const cleanUsername = username.toLowerCase().trim();

    // Check if username or email already exists
    const existing = await UserModel.findOne({
      $or: [
        { username: cleanUsername },
        { email: `${cleanUsername}@fieldservice.local` }
      ]
    });

    if (existing) {
      res.status(409).json({
        error: 'CONFLICT',
        message: `Technician username '${cleanUsername}' is already in use`
      });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const newTech = await UserModel.create({
      fullName: fullName.trim(),
      username: cleanUsername,
      email: `${cleanUsername}@fieldservice.local`,
      passwordHash,
      role: 'Technician',
      phoneNumber: (phoneNumber || '080-000-0000').trim(),
      isActive: true,
      technicianProfile: {
        isAvailable: true,
        skillCategory: skillCategory || 'General Maintenance'
      }
    });

    res.status(201).json({
      message: 'Technician account created successfully',
      technician: {
        id: newTech._id,
        fullName: newTech.fullName,
        username: newTech.username,
        email: newTech.email,
        phoneNumber: newTech.phoneNumber,
        role: newTech.role,
        technicianProfile: newTech.technicianProfile
      }
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to create technician account'
    });
  }
}

export async function getTechnicians(req: Request, res: Response): Promise<void> {
  try {
    const technicians = await UserModel.find({
      role: 'Technician',
      isActive: true
    }).select('-passwordHash').lean();

    // Calculate active ticket load for each technician
    const techList = await Promise.all(
      technicians.map(async (tech) => {
        const activeCount = await TicketModel.countDocuments({
          assignedTechnicianId: tech._id,
          status: { $in: ['Assigned', 'InProgress'] }
        });

        return {
          id: tech._id,
          fullName: tech.fullName,
          username: tech.username || tech.email.split('@')[0],
          email: tech.email,
          phoneNumber: tech.phoneNumber,
          skillCategory: tech.technicianProfile?.skillCategory || 'General',
          isAvailable: tech.technicianProfile?.isAvailable ?? true,
          activeTicketCount: activeCount
        };
      })
    );

    res.status(200).json({
      technicians: techList
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'Failed to list technicians'
    });
  }
}