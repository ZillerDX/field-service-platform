import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { config } from '../config';
import { UserModel, UserRole } from '../models/User';
import { AuthenticatedRequest } from '../middleware/auth';

export async function login(req: Request, res: Response): Promise<void> {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      res.status(400).json({
        error: 'BAD_REQUEST',
        message: 'Email and password are required'
      });
      return;
    }

    const user = await UserModel.findOne({ email: email.toLowerCase().trim() });

    if (!user || !user.isActive) {
      res.status(401).json({
        error: 'UNAUTHORIZED',
        message: 'Invalid email or password'
      });
      return;
    }

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      res.status(401).json({
        error: 'UNAUTHORIZED',
        message: 'Invalid email or password'
      });
      return;
    }

    const payload = { userId: user._id.toString(), role: user.role };

    const accessToken = jwt.sign(payload, config.jwtSecret, {
      expiresIn: config.jwtExpiresIn as any
    });

    const refreshToken = jwt.sign(payload, config.jwtRefreshSecret, {
      expiresIn: config.jwtRefreshExpiresIn as any
    });

    res.status(200).json({
      message: 'Login successful',
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        role: user.role,
        phoneNumber: user.phoneNumber,
        technicianProfile: user.technicianProfile
      }
    });
  } catch (error: any) {
    res.status(500).json({
      error: 'INTERNAL_SERVER_ERROR',
      message: error.message || 'An unexpected error occurred during login'
    });
  }
}

export async function getMe(req: AuthenticatedRequest, res: Response): Promise<void> {
  if (!req.user) {
    res.status(401).json({ error: 'UNAUTHORIZED', message: 'Not authenticated' });
    return;
  }

  res.status(200).json({
    user: {
      id: req.user._id,
      fullName: req.user.fullName,
      email: req.user.email,
      role: req.user.role,
      phoneNumber: req.user.phoneNumber,
      technicianProfile: req.user.technicianProfile
    }
  });
}

export async function refreshToken(req: Request, res: Response): Promise<void> {
  const { refreshToken } = req.body;
  if (!refreshToken) {
    res.status(400).json({ error: 'BAD_REQUEST', message: 'Refresh token is required' });
    return;
  }

  try {
    const decoded = jwt.verify(refreshToken, config.jwtRefreshSecret) as {
      userId: string;
      role: UserRole;
    };
    const user = await UserModel.findById(decoded.userId);

    if (!user || !user.isActive) {
      res.status(401).json({ error: 'UNAUTHORIZED', message: 'User invalid or inactive' });
      return;
    }

    const newAccessToken = jwt.sign(
      { userId: user._id.toString(), role: user.role },
      config.jwtSecret,
      { expiresIn: config.jwtExpiresIn as any }
    );

    res.status(200).json({ accessToken: newAccessToken });
  } catch (err) {
    res.status(401).json({ error: 'UNAUTHORIZED', message: 'Invalid or expired refresh token' });
  }
}
