import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/tickets/domain/entities/ticket_entity.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_event.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_state.dart';
import 'package:field_service_mobile/features/technician/presentation/widgets/radar_geofence_widget.dart';
import 'package:field_service_mobile/features/technician/presentation/widgets/evidence_capture_widget.dart';
import 'package:field_service_mobile/features/technician/presentation/widgets/spare_parts_widget.dart';
import 'package:field_service_mobile/features/technician/presentation/widgets/signature_pad_widget.dart';

class JobExecutionScreen extends StatefulWidget {
  final String ticketId;

  const JobExecutionScreen({super.key, required this.ticketId});

  @override
  State<JobExecutionScreen> createState() => _JobExecutionScreenState();
}

class _JobExecutionScreenState extends State<JobExecutionScreen> {
  bool _isWithinGeofence = false;
  List<Map<String, dynamic>> _partsUsed = [];
  String? _beforePhoto;
  String? _afterPhoto;
  String? _signature;

  void _startJob(TicketEntity ticket) {
    if (!_isWithinGeofence) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คุณอยู่นอกระยะ 200 เมตร กรุณาเดินทางเข้าสู่จุดเกิดเหตุเพื่อเริ่มงาน'),
          backgroundColor: AppTheme.warning,
        ),
      );
      return;
    }
    context.read<TicketBloc>().add(
          UpdateTicketStatusEvent(ticketId: ticket.id, status: 'In Progress'),
        );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('เริ่มการปฏิบัติงานแล้ว สถานะเปลี่ยนเป็น In Progress'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  void _completeJob(TicketEntity ticket) {
    if (_signature == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาให้ลูกค้าลงนามในช่องลายเซ็นก่อนส่งมอบงาน'),
          backgroundColor: AppTheme.danger,
        ),
      );
      return;
    }

    context.read<TicketBloc>().add(
          CompleteJobEvent(
            ticketId: ticket.id,
            parts: _partsUsed,
            beforeImage: _beforePhoto,
            afterImage: _afterPhoto,
            signature: _signature,
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ปิดงานและส่งมอบงานให้ลูกค้าเรียบร้อยแล้ว'),
        backgroundColor: AppTheme.success,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ปฏิบัติงานซ่อมภาคสนาม'),
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          TicketEntity? ticket;
          if (state is TicketLoaded) {
            try {
              ticket = state.tickets.firstWhere((t) => t.id == widget.ticketId);
            } catch (_) {
              ticket = null;
            }
          }

          if (ticket == null) {
            return const Center(child: Text('ไม่พบข้อมูลงาน', style: TextStyle(color: AppTheme.textMuted)));
          }

          final isInProgress = ticket.status == 'In Progress';
          final isCompleted = ticket.status == 'Completed';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ticket Overview Bar
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket.ticketNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ticket.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          ticket.status,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 1. Radar Geofencing Widget
                RadarGeofenceWidget(
                  ticketLat: ticket.latitude,
                  ticketLon: ticket.longitude,
                  onGeofenceStatusChanged: (isWithin) {
                    setState(() {
                      _isWithinGeofence = isWithin;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Start Job Button (if not yet in progress)
                if (ticket.status == 'Assigned') ...[
                  ElevatedButton.icon(
                    onPressed: _isWithinGeofence ? () => _startJob(ticket!) : null,
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: Text(_isWithinGeofence ? 'เริ่มปฏิบัติงาน (Check-in & Start Job)' : 'อยู่นอกระยะ 200ม. (ไม่สามารถเริ่มงานได้)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isWithinGeofence ? AppTheme.primary : AppTheme.border,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 2. Evidence Capture (Before & After)
                EvidenceCaptureWidget(
                  onEvidenceChanged: (before, after) {
                    _beforePhoto = before;
                    _afterPhoto = after;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Spare Parts Widget
                SparePartsWidget(
                  onPartsChanged: (parts) {
                    _partsUsed = parts;
                  },
                ),
                const SizedBox(height: 16),

                // 4. Customer Sign-off Pad
                SignaturePadWidget(
                  onSignatureChanged: (sig) {
                    _signature = sig;
                  },
                ),
                const SizedBox(height: 24),

                // Complete Job Button
                if (!isCompleted) ...[
                  ElevatedButton.icon(
                    onPressed: isInProgress ? () => _completeJob(ticket!) : null,
                    icon: const Icon(Icons.task_alt_rounded),
                    label: const Text('ปิดงานและส่งมอบให้ลูกค้า (Complete Service)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.success,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}
