import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:field_service_mobile/features/tickets/domain/entities/ticket_entity.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_event.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_state.dart';

class CustomerPortalScreen extends StatefulWidget {
  const CustomerPortalScreen({super.key});

  @override
  State<CustomerPortalScreen> createState() => _CustomerPortalScreenState();
}

class _CustomerPortalScreenState extends State<CustomerPortalScreen> {
  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(const FetchTicketsEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.business_center_outlined, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('ระบบแจ้งซ่อม / Customer Portal'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              context.read<AuthBloc>().add(LogoutSubmittedEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }

          List<TicketEntity> tickets = [];
          bool isOffline = false;

          if (state is TicketLoaded) {
            tickets = state.tickets;
            isOffline = state.isOffline;
          }

          return Column(
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off_rounded, size: 16, color: AppTheme.warning),
                      SizedBox(width: 8),
                      Text(
                        'กำลังแสดงข้อมูลแคชออฟไลน์ (Offline Mode)',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'รายการแจ้งซ่อมของคุณ (${tickets.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => context.push('/customer/create-ticket'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('แจ้งซ่อมใหม่'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 38),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: tickets.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox_rounded, size: 54, color: AppTheme.textMuted),
                            const SizedBox(height: 12),
                            const Text(
                              'ยังไม่มีประวัติการแจ้งซ่อม',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                            ),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/customer/create-ticket'),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('สร้างใบแจ้งซ่อมใบแรก'),
                              style: OutlinedButton.styleFrom(minimumSize: const Size(200, 44)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: tickets.length,
                          itemBuilder: (context, index) {
                            final ticket = tickets[index];
                            return _buildTicketCard(context, ticket);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, TicketEntity ticket) {
    Color statusBg = AppTheme.surface;
    Color statusFg = AppTheme.textSecondary;

    switch (ticket.status) {
      case 'Pending':
        statusBg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        statusFg = const Color(0xFF60A5FA);
        break;
      case 'Assigned':
        statusBg = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
        statusFg = const Color(0xFFA78BFA);
        break;
      case 'In Progress':
        statusBg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        statusFg = const Color(0xFFFBBF24);
        break;
      case 'Completed':
        statusBg = const Color(0xFF10B981).withValues(alpha: 0.15);
        statusFg = const Color(0xFF34D399);
        break;
    }

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push('/ticket/${ticket.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.ticketNumber,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      ticket.status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusFg,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                ticket.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ticket.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: AppTheme.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      ticket.locationName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ),
                  if (ticket.assignedToName != null) ...[
                    const Icon(Icons.handyman_outlined, size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 4),
                    Text(
                      ticket.assignedToName!,
                      style: const TextStyle(fontSize: 12, color: AppTheme.primaryLight, fontWeight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
