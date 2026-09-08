import dotenv from 'dotenv';
dotenv.config();

export const config = {
  port: parseInt(process.env.PORT || '5001', 10),
  mongoUri: process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/field_service_platform',
  jwtSecret: process.env.JWT_SECRET || 'fsm_sprint1_jwt_secret_key_2026_super_secure',
  jwtExpiresIn: process.env.JWT_EXPIRES_IN || '60m',
  jwtRefreshSecret: process.env.JWT_REFRESH_SECRET || 'fsm_sprint1_refresh_secret_key_2026',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  geofenceRadiusMeters: parseInt(process.env.GEOFENCE_RADIUS_METERS || '200', 10),
  uploadDir: process.env.UPLOAD_DIR || 'uploads'
};
