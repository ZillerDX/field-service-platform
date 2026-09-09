import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';
import '../../../tickets/presentation/bloc/ticket_event.dart';
import '../../../tickets/presentation/bloc/ticket_state.dart';

class TechHubScreen extends StatefulWidget {
  const TechHubScreen({super.key});

  @override
  State<TechHubScreen> createState() => _TechHubScreenState();
}

class _TechHubScreenState extends State<TechHubScreen> {
  final AppLanguage _lang = AppLanguage();
  bool _isAvailable = true;

  @override
  void initState() {
    super.initState();
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
    String techName = _lang.t('ช่างเทคนิค', 'Technician');
    final authState = context.watch<AuthBloc>().state;
    if (authState is Authenticated) {
      techName = authState.user.name;
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.shield_outlined, color: AppTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'FieldOps Nexus',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _lang.t('ศูนย์รวมงานช่าง / Hub', 'Technician Operations Hub'),
                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Language Switcher Pill
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: InkWell(
              onTap: () => _lang.toggleLanguage(),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language_rounded, size: 14, color: AppTheme.primaryLight),
                    const SizedBox(width: 4),
                    Text(
                      _lang.isThai ? 'TH' : 'EN',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Profile Button
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppTheme.textPrimary),
            tooltip: _lang.t('โปรไฟล์', 'Profile'),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: BlocBuilder<TicketBloc, TicketState>(
        builder: (context, state) {
          List<TicketEntity> tickets = [];
          bool isOffline = false;

          if (state is TicketLoaded) {
            tickets = state.tickets;
            isOffline = state.isOffline;
          }

          final assignedCount = tickets.where((t) => t.status == 'Assigned').length;
          final inProgressCount = tickets.where((t) => t.status == 'In Progress').length;
          final completedCount = tickets.where((t) => t.status == 'Completed').length;
          final totalCount = tickets.length;

          return RefreshIndicator(
            color: AppTheme.primary,
            backgroundColor: AppTheme.surface,
            onRefresh: () async {
              context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.warning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.warning.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off_rounded, size: 18, color: AppTheme.warning),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _lang.t(
                                'โหมดออฟไลน์: บันทึกข้อมูลในเครื่อง ซิงค์อัตโนมัติเมื่อต่อเน็ต',
                                'Offline Mode: Local cache active. Will auto-sync when online.',
                              ),
                              style: const TextStyle(fontSize: 12, color: AppTheme.warning, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Technician Status & Greeting Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.surface,
                          AppTheme.card.withValues(alpha: 0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppTheme.primary.withValues(alpha: 0.25),
                              child: const Icon(Icons.person_rounded, color: AppTheme.primaryLight, size: 28),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lang.t('สวัสดี, $techName', 'Welcome, $techName'),
                                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _lang.t('ช่างบริการภาคสนามระดับชำนาญการ', 'Senior Field Service Specialist'),
                                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            // Availability Toggle Pill
                            InkWell(
                              onTap: () {
                                setState(() => _isAvailable = !_isAvailable);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _isAvailable
                                          ? _lang.t('สถานะ: พร้อมรับงานซ่อม', 'Status: Ready for dispatch')
                                          : _lang.t('สถานะ: พักการทำงาน', 'Status: On break / Unavailable'),
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _isAvailable
                                      ? AppTheme.success.withValues(alpha: 0.15)
                                      : AppTheme.textMuted.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _isAvailable ? AppTheme.success : AppTheme.textMuted,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isAvailable ? AppTheme.success : AppTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _isAvailable ? _lang.t('พร้อมรับงาน', 'Active') : _lang.t('พักงาน', 'Away'),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: _isAvailable ? AppTheme.success : AppTheme.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(height: 1, color: AppTheme.border),
                        const SizedBox(height: 14),
                        // Quick Stats Row
                        Row(
                          children: [
                            _buildQuickStat(
                              title: _lang.t('งานใหม่', 'New'),
                              count: assignedCount,
                              color: AppTheme.danger,
                            ),
                            _buildVerticalDivider(),
                            _buildQuickStat(
                              title: _lang.t('กำลังทำ', 'In-Progress'),
                              count: inProgressCount,
                              color: AppTheme.warning,
                            ),
                            _buildVerticalDivider(),
                            _buildQuickStat(
                              title: _lang.t('เสร็จสิ้น', 'Completed'),
                              count: completedCount,
                              color: AppTheme.success,
                            ),
                            _buildVerticalDivider(),
                            _buildQuickStat(
                              title: _lang.t('รวมทั้งหมด', 'Total'),
                              count: totalCount,
                              color: AppTheme.primaryLight,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  // Section Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lang.t('เมนูควบคุมการทำงาน', 'Operational Dashboard'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Text(
                        _lang.t('แตะเพื่อเข้าสู่รายการ', 'Tap card to view'),
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Hub Menu Grid (กล่องเมนูด้านนอก)
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.05,
                    children: [
                      // BOX 1: Assigned Tasks (WITH PROMINENT RED NOTIFICATION BADGE)
                      _buildHubMenuCard(
                        title: _lang.t('งานที่ได้รับมอบหมาย', 'Assigned Tasks'),
                        subtitle: _lang.t('งานใหม่รอเริ่มปฏิบัติการ', 'New jobs awaiting start'),
                        icon: Icons.assignment_late_outlined,
                        badgeCount: assignedCount,
                        badgeColor: AppTheme.danger, // STRICT RED #EF4444
                        accentColor: AppTheme.danger,
                        onTap: () {
                          context.push('/technician/workspace?filter=Assigned');
                        },
                      ),

                      // BOX 2: In Progress
                      _buildHubMenuCard(
                        title: _lang.t('กำลังปฏิบัติงาน', 'In Progress'),
                        subtitle: _lang.t('ไซต์งานที่กำลังดำเนินการ', 'Active jobs & check-in'),
                        icon: Icons.engineering_outlined,
                        badgeCount: inProgressCount,
                        badgeColor: AppTheme.warning,
                        accentColor: AppTheme.warning,
                        onTap: () {
                          context.push('/technician/workspace?filter=In Progress');
                        },
                      ),

                      // BOX 3: Completed History
                      _buildHubMenuCard(
                        title: _lang.t('ประวัติงานซ่อม', 'Work History'),
                        subtitle: _lang.t('งานที่ปิดเรียบร้อย & ลายเซ็น', 'Completed jobs & signatures'),
                        icon: Icons.task_alt_rounded,
                        badgeCount: completedCount,
                        badgeColor: AppTheme.success,
                        accentColor: AppTheme.success,
                        onTap: () {
                          context.push('/technician/workspace?filter=Completed');
                        },
                      ),

                      // BOX 4: All Tickets
                      _buildHubMenuCard(
                        title: _lang.t('รายการงานทั้งหมด', 'All Tickets'),
                        subtitle: _lang.t('ดูภาพรวมงานซ่อมทั้งหมด', 'View all maintenance items'),
                        icon: Icons.format_list_bulleted_rounded,
                        badgeCount: totalCount,
                        badgeColor: AppTheme.primaryLight,
                        accentColor: AppTheme.primary,
                        onTap: () {
                          context.push('/technician/workspace?filter=All');
                        },
                      ),

                      // BOX 5: Field Radar & Navigation
                      _buildHubMenuCard(
                        title: _lang.t('เรดาร์ & ไซต์งาน', 'Radar & Geofence'),
                        subtitle: _lang.t('ตรวจจับระยะทาง 200m ไซต์งาน', 'Active GPS radius check'),
                        icon: Icons.radar_rounded,
                        accentColor: const Color(0xFF06B6D4), // Cyan
                        onTap: () {
                          // If there's an in-progress ticket, jump right in, else go to workspace
                          final active = tickets.where((t) => t.status == 'In Progress' || t.status == 'Assigned').toList();
                          if (active.isNotEmpty) {
                            context.push('/technician/job/${active.first.id}');
                          } else {
                            context.push('/technician/workspace?filter=All');
                          }
                        },
                      ),

                      // BOX 6: Profile & Settings
                      _buildHubMenuCard(
                        title: _lang.t('โปรไฟล์ & ตั้งค่า', 'Profile & Settings'),
                        subtitle: _lang.t('ข้อมูลช่าง ภาษา และระบบ', 'Account, language & status'),
                        icon: Icons.manage_accounts_outlined,
                        accentColor: AppTheme.primaryLight,
                        onTap: () {
                          context.push('/profile');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStat({
    required String title,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: AppTheme.borderSubtle,
    );
  }

  Widget _buildHubMenuCard({
    required String title,
    required String subtitle,
    required IconData icon,
    int? badgeCount,
    Color? badgeColor,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: accentColor.withValues(alpha: 0.15),
        highlightColor: accentColor.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.border, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: accentColor, size: 22),
                  ),
                  if (badgeCount != null && badgeCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor ?? AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (badgeColor ?? AppTheme.primary).withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        badgeCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
