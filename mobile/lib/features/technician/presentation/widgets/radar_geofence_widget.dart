import 'package:flutter/material.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/core/utils/geofence_util.dart';

class RadarGeofenceWidget extends StatefulWidget {
  final double ticketLat;
  final double ticketLon;
  final Function(bool isWithin) onGeofenceStatusChanged;

  const RadarGeofenceWidget({
    super.key,
    required this.ticketLat,
    required this.ticketLon,
    required this.onGeofenceStatusChanged,
  });

  @override
  State<RadarGeofenceWidget> createState() => _RadarGeofenceWidgetState();
}

class _RadarGeofenceWidgetState extends State<RadarGeofenceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late double _techLat;
  late double _techLon;
  bool _isSimulatedOnSite = false;

  @override
  void initState() {
    super.initState();
    // Default initial tech position: ~850m away
    _techLat = widget.ticketLat + 0.0075;
    _techLon = widget.ticketLon + 0.0055;

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkGeofence();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _checkGeofence() {
    final within = GeofenceUtil.isWithinGeofence(
      _techLat,
      _techLon,
      widget.ticketLat,
      widget.ticketLon,
      thresholdMeters: 200.0,
    );
    widget.onGeofenceStatusChanged(within);
  }

  void _toggleSimulation() {
    setState(() {
      _isSimulatedOnSite = !_isSimulatedOnSite;
      if (_isSimulatedOnSite) {
        // Position within 45 meters
        _techLat = widget.ticketLat + 0.0003;
        _techLon = widget.ticketLon + 0.0002;
      } else {
        // Position ~850 meters away
        _techLat = widget.ticketLat + 0.0075;
        _techLon = widget.ticketLon + 0.0055;
      }
    });
    _checkGeofence();
  }

  @override
  Widget build(BuildContext context) {
    final distanceMeters = GeofenceUtil.calculateDistanceMeters(
      _techLat,
      _techLon,
      widget.ticketLat,
      widget.ticketLon,
    );
    final isWithin = distanceMeters <= 200.0;

    final radarColor = isWithin ? AppTheme.success : AppTheme.warning;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWithin ? AppTheme.success.withValues(alpha: 0.5) : AppTheme.border,
          width: isWithin ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.radar_rounded, color: radarColor, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'GPS Radar Geofencing (200m)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: radarColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isWithin ? 'ในพื้นที่บริการ' : 'อยู่นอกระยะ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: radarColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Animated Radar Visualizer
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final scale = 1.0 + (_pulseController.value * 0.35);
                    final opacity = (1.0 - _pulseController.value).clamp(0.0, 1.0);
                    return Container(
                      width: 90 * scale,
                      height: 90 * scale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: radarColor.withValues(alpha: opacity * 0.5),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: radarColor.withValues(alpha: 0.15),
                    border: Border.all(color: radarColor, width: 2),
                  ),
                  child: Center(
                    child: Icon(
                      isWithin ? Icons.check_circle_outline_rounded : Icons.location_searching_rounded,
                      color: radarColor,
                      size: 34,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Distance info
          Text(
            'ระยะห่างจากจุดเกิดเหตุ: ${GeofenceUtil.formatDistance(distanceMeters)}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isWithin
                ? 'ตรวจพบตำแหน่งช่างอยู่ในรัศมี 200 ม. อนุญาตให้กดเริ่มงานได้'
                : 'ช่างต้องเดินทางเข้าใกล้จุดเกิดเหตุในระยะไม่เกิน 200 ม. เพื่อเริ่มงาน',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isWithin ? AppTheme.success : AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Testing Simulation Switch
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'จำลองพิกัดช่างมาถึงหน้างาน (Simulate Arrived)',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Switch(
                  value: _isSimulatedOnSite,
                  activeThumbColor: AppTheme.success,
                  onChanged: (val) => _toggleSimulation(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

