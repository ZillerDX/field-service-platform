import { Schema, model, Document, Types } from 'mongoose';

export type UserRole = 'Customer' | 'Technician' | 'Admin';

export interface ITechnicianProfile {
  skillCategory?: string;
  isAvailable: boolean;
  currentLocation?: {
    type: 'Point';
    coordinates: [number, number]; // [longitude, latitude]
  };
  lastLocationUpdate?: Date;
}

export interface IUser extends Document {
  _id: Types.ObjectId;
  fullName: string;
  email: string;
  passwordHash: string;
  role: UserRole;
  phoneNumber: string;
  isActive: boolean;
  technicianProfile?: ITechnicianProfile;
  createdAt: Date;
  updatedAt: Date;
}

const PointSchema = new Schema(
  {
    type: {
      type: String,
      enum: ['Point'],
      required: true,
      default: 'Point'
    },
    coordinates: {
      type: [Number],
      required: true
    }
  },
  { _id: false }
);

export const UserSchema = new Schema<IUser>(
  {
    fullName: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, index: true, lowercase: true, trim: true },
    passwordHash: { type: String, required: true },
    role: { type: String, required: true, enum: ['Customer', 'Technician', 'Admin'], index: true },
    phoneNumber: { type: String, required: true, trim: true },
    isActive: { type: Boolean, default: true, index: true },
    technicianProfile: {
      type: {
        skillCategory: { type: String },
        isAvailable: { type: Boolean, default: true },
        currentLocation: {
          type: PointSchema,
          required: false
        },
        lastLocationUpdate: { type: Date }
      },
      required: false,
      _id: false
    }
  },
  { timestamps: true }
);

UserSchema.index({ 'technicianProfile.currentLocation': '2dsphere' }, { sparse: true });

export const UserModel = model<IUser>('User', UserSchema);
