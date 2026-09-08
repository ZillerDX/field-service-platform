import { Schema, model, Document, Types } from 'mongoose';

export type TicketStatus =
  | 'Pending'
  | 'Assigned'
  | 'EnRoute'
  | 'InProgress'
  | 'Completed'
  | 'Cancelled';

export type PhotoType = 'Before' | 'After' | 'SiteReport';

export interface ITicketItem {
  itemName: string;
  quantity: number;
  unitPrice: number;
}

export interface ITicketAttachment {
  photoType: PhotoType;
  fileUrl: string;
  uploadedBy: Types.ObjectId;
  uploadedAt: Date;
}

export interface ITicket extends Document {
  _id: Types.ObjectId;
  ticketCode: string;
  customer: Types.ObjectId;
  assignedTechnician?: Types.ObjectId | null;
  title: string;
  description: string;
  status: TicketStatus;
  location: {
    type: 'Point';
    coordinates: [number, number]; // [longitude, latitude]
    address: string;
  };
  items: ITicketItem[];
  attachments: ITicketAttachment[];
  customerSignatureUrl?: string | null;
  closedAt?: Date | null;
  createdAt: Date;
  updatedAt: Date;
}

export const TicketSchema = new Schema<ITicket>(
  {
    ticketCode: { type: String, required: true, unique: true, index: true },
    customer: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    assignedTechnician: { type: Schema.Types.ObjectId, ref: 'User', default: null, index: true },
    title: { type: String, required: true, trim: true },
    description: { type: String, required: true },
    status: {
      type: String,
      required: true,
      enum: ['Pending', 'Assigned', 'EnRoute', 'InProgress', 'Completed', 'Cancelled'],
      default: 'Pending',
      index: true
    },
    location: {
      type: { type: String, enum: ['Point'], default: 'Point', required: true },
      coordinates: { type: [Number], required: true }, // [longitude, latitude]
      address: { type: String, required: true }
    },
    items: [
      {
        itemName: { type: String, required: true, trim: true },
        quantity: { type: Number, required: true, min: 1 },
        unitPrice: { type: Number, required: true, min: 0 }
      }
    ],
    attachments: [
      {
        photoType: { type: String, enum: ['Before', 'After', 'SiteReport'], required: true },
        fileUrl: { type: String, required: true },
        uploadedBy: { type: Schema.Types.ObjectId, ref: 'User', required: true },
        uploadedAt: { type: Date, default: Date.now }
      }
    ],
    customerSignatureUrl: { type: String, default: null },
    closedAt: { type: Date, default: null }
  },
  { timestamps: true }
);

TicketSchema.index({ location: '2dsphere' });

export const TicketModel = model<ITicket>('Ticket', TicketSchema);
