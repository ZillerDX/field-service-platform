import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:field_service_mobile/features/tickets/domain/entities/ticket_entity.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_event.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_state.dart';

class DispatcherScreen extends StatefulWidget {
  const DispatcherScreen({super.key});

  @override
  State<DispatcherScreen> createState() => _DispatcherScreenState();
}

class _DispatcherScreenState extends State<DispatcherScreen> {
  String _selectedFilter = 'All';

  final List<Map<String, String>> _technicians = [
    {'id': 'tech_vichai', 'name': 'ช่างวิชัย (Vichai)', 'phone': '081-999-8877'},
    {'id': 'tech_somporn', 'name': 'ช่างสมพร (Somporn)', 'phone': '082-333-4455'},
  ];

  @override
  void initState() {
    super.initState();
    context.read<TicketBloc>().add(const FetchTicketsEvent());
  }

  void _showAssignModal(TicketEntity ticket) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'มอบหมายงาน: ${ticket.ticketNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  ticket.title,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                const Text('เลือกช่างเทคนิคที่พร้อมปฏิบัติงาน:', style: TextStyle(fontSize: 13, color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                ..._technicians.map((tech) {
                  return ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.handyman_rounded, color: Colors.white, size: 18),
                    ),
                    title: Text(tech['name']!, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: Text(tech['phone']!, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    onTap: () {
                      context.read<TicketBloc>().add(
                            AssignTicketEvent(
                              ticketId: ticket.id,
                              technicianId: tech['id']!,
                              technicianName: tech['name']!,
                            ),
                          );
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('มอบหมายงานให้ ${tech['name']} สำเร็จ'),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize_outlined, color: AppTheme.primaryLight, size: 22),
            SizedBox(width: 8),
            Text('แผงควบคุมแอดมิน / Dispatch Matrix'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true)),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => context.read<AuthBloc>().add(LogoutSubmittedEvent()),
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          if (state is TicketLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          List<TicketEntity> allTickets = [];
          if (state is TicketLoaded) {
            allTickets = state.tickets;
          }

          final filtered = allTickets.where((t) {
            if (_selectedFilter == 'All') return true;
            return t.status == _selectedFilter;
          }).toList();

          return Column(
            children: [
              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _buildChip('All', 'ทั้งหมด (${allTickets.length})'),
                    const SizedBox(width: 8),
                    _buildChip('Pending', 'รอจ่ายงาน'),
                    const SizedBox(width: 8),
                    _buildChip('Assigned', 'จ่ายงานแล้ว'),
                    const SizedBox(width: 8),
                    _buildChip('In Progress', 'กำลังซ่อม'),
                    const SizedBox(width: 8),
                    _buildChip('Completed', 'เสร็จสิ้น'),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? const Center(child: Text('ไม่มีรายการตามเงื่อนไขที่เลือก', style: TextStyle(color: AppTheme.textMuted)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final ticket = filtered[index];
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
                                        style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, color: AppTheme.primaryLight),
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
                                  const SizedBox(height: 8),
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
                                      const Icon(Icons.person_outline, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(ticket.customerName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                      const Spacer(),
                                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textMuted),
                                      const SizedBox(width: 4),
                                      Text(ticket.locationName, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        ticket.assignedToName != null ? 'ช่าง: ${ticket.assignedToName}' : 'ยังไม่ได้มอบหมาย',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: ticket.assignedToName != null ? FontWeight.w600 : FontWeight.normal,
                                          color: ticket.assignedToName != null ? AppTheme.primaryLight : AppTheme.textMuted,
                                        ),
                                      ),
                                      ElevatedButton.icon(
                                        onPressed: () => _showAssignModal(ticket),
                                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 15),
                                        label: Text(
                                          ticket.assignedToName != null ? 'เปลี่ยนช่าง' : 'จ่ายงานให้ช่าง',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        style: ElevatedButton.styleFrom(
                                          minimumSize: const Size(0, 36),
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildChip(String filterKey, String label) {
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
}
