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

class TechWorkspaceScreen extends StatefulWidget {
  const TechWorkspaceScreen({super.key});

  @override
  State<TechWorkspaceScreen> createState() => _TechWorkspaceScreenState();
}

class _TechWorkspaceScreenState extends State<TechWorkspaceScreen> {
  String _selectedFilter = 'All';

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
            Icon(Icons.handyman_outlined, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('พื้นที่ทำงานช่าง / Technician Workspace'),
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
            onPressed: () {
              context.read<AuthBloc>().add(LogoutSubmittedEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          List<TicketEntity> allTickets = [];
          bool isOffline = false;

          if (state is TicketLoaded) {
            allTickets = state.tickets;
            isOffline = state.isOffline;
          }

          final filtered = allTickets.where((t) {
            if (_selectedFilter == 'All') return true;
            return t.status == _selectedFilter;
          }).toList();

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
                        'กำลังใช้งานโหมดออฟไลน์ ข้อมูลจะซิงค์เมื่อเชื่อมต่อเน็ต',
                        style: TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),

              // Filter row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildFilterChip('All', 'ทั้งหมด (${allTickets.length})'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Assigned', 'งานใหม่ / มอบหมายแล้ว'),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Progress', 'กำลังปฏิบัติงาน'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', 'ปิดงานเรียบร้อย'),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text('ไม่มีรายการงานตามเงื่อนไขที่เลือก', style: TextStyle(color: AppTheme.textMuted)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final ticket = filtered[index];
                          return _buildTechCard(context, ticket);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String filterKey, String label) {
    final isSelected = _selectedFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppTheme.primary,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedFilter = filterKey);
      },
    );
  }

  Widget _buildTechCard(BuildContext context, TicketEntity ticket) {
    return Card(
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
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryLight,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    ticket.status,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primaryLight),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              ticket.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              ticket.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ticket.locationName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/ticket/${ticket.id}'),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('ดูรายละเอียด', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/technician/job/${ticket.id}'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      ticket.status == 'Completed' ? 'ดูรายงาน' : 'ปฏิบัติงาน',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
