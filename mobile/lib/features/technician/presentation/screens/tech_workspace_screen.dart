import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';
import '../../../tickets/presentation/bloc/ticket_event.dart';
import '../../../tickets/presentation/bloc/ticket_state.dart';

class TechWorkspaceScreen extends StatefulWidget {
  final String initialFilter;
  const TechWorkspaceScreen({super.key, this.initialFilter = 'All'});

  @override
  State<TechWorkspaceScreen> createState() => _TechWorkspaceScreenState();
}

class _TechWorkspaceScreenState extends State<TechWorkspaceScreen> {
  late String _selectedFilter;
  final AppLanguage _lang = AppLanguage();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _lang.addListener(_onLanguageChanged);
    context.read<TicketBloc>().add(const FetchTicketsEvent());
  }

  @override
  void dispose() {
    _lang.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/technician');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.handyman_outlined, color: AppTheme.primaryLight, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _lang.t('รายการงานช่าง', 'Technician Workspace'),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: _lang.t('รีเฟรช', 'Refresh'),
            onPressed: () {
              context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true));
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            tooltip: _lang.t('โปรไฟล์', 'Profile'),
            onPressed: () => context.push('/profile'),
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

          final assignedCount = allTickets.where((t) => t.status == 'Assigned').length;

          return Column(
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  color: AppTheme.warning.withValues(alpha: 0.15),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, size: 16, color: AppTheme.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _lang.t(
                            'กำลังใช้งานโหมดออฟไลน์ ข้อมูลจะซิงค์เมื่อเชื่อมต่อเน็ต',
                            'Offline mode active. Changes will sync when reconnected.',
                          ),
                          style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
                        ),
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
                    _buildFilterChip('All', _lang.t('ทั้งหมด (${allTickets.length})', 'All (${allTickets.length})')),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      'Assigned',
                      _lang.t('มอบหมายแล้ว ($assignedCount)', 'Assigned ($assignedCount)'),
                      badgeCount: assignedCount,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip('In Progress', _lang.t('กำลังทำ', 'In Progress')),
                    const SizedBox(width: 8),
                    _buildFilterChip('Completed', _lang.t('ปิดงานแล้ว', 'Completed')),
                  ],
                ),
              ),

              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 48, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                            const SizedBox(height: 12),
                            Text(
                              _lang.t('ไม่มีรายการงานตามเงื่อนไขที่เลือก', 'No tickets found for this filter'),
                              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
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

  Widget _buildFilterChip(String filterKey, String label, {int? badgeCount}) {
    final isSelected = _selectedFilter == filterKey;
    final isAssigned = filterKey == 'Assigned';
    final hasActiveAssigned = isAssigned && (badgeCount ?? 0) > 0;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          if (hasActiveAssigned && !isSelected) ...[
            const SizedBox(width: 6),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppTheme.danger,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
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
    Color statusColor;
    String statusLabel;

    switch (ticket.status) {
      case 'In Progress':
        statusColor = AppTheme.warning;
        statusLabel = _lang.t('กำลังทำ', 'In Progress');
        break;
      case 'Completed':
        statusColor = AppTheme.success;
        statusLabel = _lang.t('ปิดงานแล้ว', 'Completed');
        break;
      case 'Assigned':
      default:
        statusColor = AppTheme.danger;
        statusLabel = _lang.t('งานใหม่', 'Assigned');
        break;
    }

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
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
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
                    label: Text(_lang.t('รายละเอียด', 'Details'), style: const TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.push('/technician/job/${ticket.id}'),
                    icon: const Icon(Icons.play_arrow_rounded, size: 16),
                    label: Text(
                      ticket.status == 'Completed'
                          ? _lang.t('ดูรายงาน', 'View Report')
                          : _lang.t('ปฏิบัติงาน', 'Execute Job'),
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
