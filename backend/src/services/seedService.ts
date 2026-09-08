import bcrypt from 'bcryptjs';
import { UserModel } from '../models/User';

export async function seedInitialUsers(): Promise<void> {
  const count = await UserModel.countDocuments();
  if (count > 0) {
    return; // Already seeded
  }

  const saltRounds = 12;

  const users = [
    {
      fullName: 'Sompong Customer (ลูกค้าทดสอบ)',
      email: 'customer@fsm.local',
      passwordHash: await bcrypt.hash('Customer123!', saltRounds),
      role: 'Customer',
      phoneNumber: '081-111-2222',
      isActive: true
    },
    {
      fullName: 'Wichai Technician (ช่างวิชัย ภาคสนาม)',
      email: 'tech1@fsm.local',
      passwordHash: await bcrypt.hash('Tech123!', saltRounds),
      role: 'Technician',
      phoneNumber: '082-333-4444',
      isActive: true,
      technicianProfile: {
        skillCategory: 'HVAC & Electrical',
        isAvailable: true,
        currentLocation: {
          type: 'Point',
          coordinates: [100.523186, 13.736717] // Bangkok Coordinates
        },
        lastLocationUpdate: new Date()
      }
    },
    {
      fullName: 'Prasert Technician (ช่างประเสริฐ ช่างประปา)',
      email: 'tech2@fsm.local',
      passwordHash: await bcrypt.hash('Tech123!', saltRounds),
      role: 'Technician',
      phoneNumber: '083-555-6666',
      isActive: true,
      technicianProfile: {
        skillCategory: 'Plumbing & Pipe System',
        isAvailable: false, // Busy/Unavailable
        currentLocation: {
          type: 'Point',
          coordinates: [100.540000, 13.750000]
        },
        lastLocationUpdate: new Date()
      }
    },
    {
      fullName: 'Supaporn Dispatcher (ผู้จัดการจ่ายงาน)',
      email: 'admin@fsm.local',
      passwordHash: await bcrypt.hash('Admin123!', saltRounds),
      role: 'Admin',
      phoneNumber: '080-999-8888',
      isActive: true
    }
  ];

  await UserModel.insertMany(users);
  console.log('✅ Default users seeded successfully for all 3 roles.');
}
