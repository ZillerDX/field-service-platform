import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/tickets/domain/entities/ticket_entity.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_state.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_state.dart';

class TicketDetailScreen extends StatelessWidget {
  final String ticketId;

  const TicketDetailScreen({super.key, required this.ticketId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('รายละเอียดใบแจ้งซ่อม'),
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          TicketEntity? ticket;
          if (state is TicketLoaded) {
            try {
              ticket = state.tickets.firstWhere((t) => t.id == ticketId);
            } catch (_) {
              ticket = null;
            }
          }

          if (ticket == null) {
            return const Center(
              child: Text('ไม่พบข้อมูลใบแจ้งซ่อม', style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final authState = context.read<AuthBloc>().state;
          final isTech = authState is Authenticated && authState.user.role == 'technician';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            ticket.ticketNumber,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryLight,
                              fontSize: 14,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              ticket.status,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        ticket.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ticket.description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Details Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      _buildRow(Icons.category_outlined, 'หมวดหมู่', ticket.category),
                      const Divider(),
                      _buildRow(Icons.priority_high_rounded, 'ระดับความเร่งด่วน', ticket.urgency),
                      const Divider(),
                      _buildRow(Icons.person_outline, 'ผู้แจ้งซ่อม', '${ticket.customerName} (${ticket.customerPhone})'),
                      const Divider(),
                      _buildRow(Icons.pin_drop_outlined, 'สถานที่', ticket.locationName),
                      const Divider(),
                      _buildRow(
                        Icons.handyman_outlined,
                        'ช่างผู้ดูแล',
                        ticket.assignedToName ?? 'ยังไม่ได้มอบหมายช่าง',
                        highlight: ticket.assignedToName != null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // If technician and assigned/in-progress, show button to open field workspace
                if (isTech && (ticket.status == 'Assigned' || ticket.status == 'In Progress')) ...[
                  ElevatedButton.icon(
                    onPressed: () => context.push('/technician/job/${ticket!.id}'),
                    icon: const Icon(Icons.navigation_rounded),
                    label: const Text('เข้าสู่พื้นที่ปฏิบัติงาน (Field Workspace)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRow(IconData icon, String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: highlight ? AppTheme.primaryLight : AppTheme.textMuted),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
              color: highlight ? AppTheme.primaryLight : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
