import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { UserModel, IUser, UserRole } from '../models/User';

export interface AuthenticatedRequest extends Request {
  user?: IUser;
}

export async function authenticateToken(
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.startsWith('Bearer ') ? authHeader.split(' ')[1] : null;

  if (!token) {
    res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Access token is missing or malformed'
    });
    return;
  }

  try {
    const decoded = jwt.verify(token, config.jwtSecret) as { userId: string; role: UserRole };
    const user = await UserModel.findById(decoded.userId);

    if (!user || !user.isActive) {
      res.status(401).json({
        error: 'UNAUTHORIZED',
        message: 'User account not found or deactivated'
      });
      return;
    }

    req.user = user;
    next();
  } catch (err) {
    res.status(401).json({
      error: 'UNAUTHORIZED',
      message: 'Invalid or expired access token'
    });
  }
}

export function requireRole(allowedRoles: UserRole[]) {
  return (req: AuthenticatedRequest, res: Response, next: NextFunction): void => {
    if (!req.user) {
      res.status(401).json({
        error: 'UNAUTHORIZED',
        message: 'User is not authenticated'
      });
      return;
    }

    if (!allowedRoles.includes(req.user.role)) {
      res.status(403).json({
        error: 'FORBIDDEN',
        message: `Role '${req.user.role}' is not authorized to access this resource`
      });
      return;
    }

    next();
  };
}
