import express, { Application, Request, Response, NextFunction } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import path from 'path';
import apiRouter from './routes/api';

export function createApp(): Application {
  const app: Application = express();

  // Non-functional requirement: Helmet security headers
  app.use(
    helmet({
      crossOriginResourcePolicy: { policy: 'cross-origin' },
      contentSecurityPolicy: false
    })
  );

  app.use(cors({ origin: '*' }));
  app.use(express.json({ limit: '10mb' }));
  app.use(express.urlencoded({ extended: true, limit: '10mb' }));

  // Static uploads folder for evidence photos & signatures
  const uploadDir = path.resolve(__dirname, '../uploads');
  app.use('/uploads', express.static(uploadDir));

  // Static public frontend portal
  const publicDir = path.resolve(__dirname, '../public');
  app.use(express.static(publicDir));

  // Health check endpoint
  app.get('/health', (_req: Request, res: Response) => {
    res.status(200).json({
      status: 'OK',
      timestamp: new Date().toISOString(),
      service: 'Field Service & Maintenance API (SRS-FSM-2026-V1)'
    });
  });

  // Mount API v1 router
  app.use('/api', apiRouter);
  app.use('/api/v1', apiRouter);

  // 404 handler
  app.use((_req: Request, res: Response) => {
    res.status(404).json({
      error: 'NOT_FOUND',
      message: 'The requested resource does not exist'
    });
  });

  // Global error handler
  app.use((err: any, _req: Request, res: Response, _next: NextFunction) => {
    console.error('Unhandled Error:', err);
    res.status(err.status || 500).json({
      error: err.name || 'INTERNAL_SERVER_ERROR',
      message: err.message || 'An internal server error occurred'
    });
  });

  return app;
}
