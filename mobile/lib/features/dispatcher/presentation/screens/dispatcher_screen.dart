import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../tickets/domain/entities/ticket_entity.dart';
import '../../../tickets/presentation/bloc/ticket_bloc.dart';
import '../../../tickets/presentation/bloc/ticket_event.dart';
import '../../../tickets/presentation/bloc/ticket_state.dart';

class DispatcherScreen extends StatefulWidget {
  const DispatcherScreen({super.key});

  @override
  State<DispatcherScreen> createState() => _DispatcherScreenState();
}

class _DispatcherScreenState extends State<DispatcherScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'All';
  final AppLanguage _lang = AppLanguage();

  bool _isLoadingTechs = false;
  List<Map<String, dynamic>> _technicians = [
    {'id': 'tech_vichai', 'name': 'ช่างวิชัย (Vichai)', 'username': 'tech_vichai', 'phone': '081-999-8877', 'activeTicketsCount': 1},
    {'id': 'tech_somporn', 'name': 'ช่างสมพร (Somporn)', 'username': 'tech_somporn', 'phone': '082-333-4455', 'activeTicketsCount': 0},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _lang.addListener(_onLangChange);
    context.read<TicketBloc>().add(const FetchTicketsEvent());
    _loadTechnicians();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lang.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  Future<void> _loadTechnicians() async {
    setState(() => _isLoadingTechs = true);
    try {
      final response = await DioClient().dio.get(ApiConstants.techniciansEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data['technicians'] ?? [];
        if (list.isNotEmpty) {
          setState(() {
            _technicians = list.map((item) {
              return {
                'id': item['id']?.toString() ?? '',
                'name': item['name']?.toString() ?? '',
                'username': item['username']?.toString() ?? '',
                'phone': item['phone']?.toString() ?? '-',
                'activeTicketsCount': item['activeTicketsCount'] ?? 0,
              };
            }).toList();
          });
        }
      }
    } catch (_) {
      // Fallback to local default if offline
    } finally {
      if (mounted) setState(() => _isLoadingTechs = false);
    }
  }

  Future<void> _showAddTechnicianDialog() async {
    final nameCtrl = TextEditingController();
    final usernameCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.border),
          ),
          title: Row(
            children: [
              const Icon(Icons.person_add_alt_1_rounded, color: AppTheme.primaryLight, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _lang.t('เพิ่มช่างเทคนิคใหม่', 'Add New Technician'),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _lang.t('สร้างบัญชีช่างเพื่อมอบหมายงานและเข้าสู่ระบบด้วยรหัสผ่านตั้งต้น', 'Create technician account for assignment and initial login'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: _lang.t('ชื่อ-นามสกุลช่าง', 'Full Name'),
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? _lang.t('กรุณาระบุชื่อช่าง', 'Name is required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: usernameCtrl,
                    decoration: InputDecoration(
                      labelText: _lang.t('ชื่อผู้ใช้ (Username)', 'Username'),
                      prefixIcon: const Icon(Icons.account_circle_outlined, size: 20),
                      hintText: 'เช่น tech_somchai',
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? _lang.t('กรุณาระบุชื่อผู้ใช้', 'Username is required') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: _lang.t('รหัสผ่านตั้งต้น', 'Initial Password'),
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? _lang.t('รหัสผ่านต้องมี 6 ตัวขึ้นไป', 'Min 6 characters') : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: phoneCtrl,
                    decoration: InputDecoration(
                      labelText: _lang.t('เบอร์โทรศัพท์', 'Phone Number'),
                      prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                      hintText: '081-xxx-xxxx',
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_lang.t('ยกเลิก', 'Cancel'), style: const TextStyle(color: AppTheme.textMuted)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final messenger = ScaffoldMessenger.of(context);
                  Navigator.pop(ctx);
                  try {
                    final res = await DioClient().dio.post(
                      ApiConstants.techniciansEndpoint,
                      data: {
                        'name': nameCtrl.text.trim(),
                        'username': usernameCtrl.text.trim().toLowerCase(),
                        'password': passCtrl.text,
                        'phone': phoneCtrl.text.trim(),
                        'role': 'Technician',
                      },
                    );
                    if (res.statusCode == 201) {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(_lang.t('เพิ่มช่าง ${nameCtrl.text} สำเร็จแล้ว', 'Technician ${nameCtrl.text} added successfully')),
                          backgroundColor: AppTheme.success,
                        ),
                      );
                      _loadTechnicians();
                    }
                  } catch (err) {
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(_lang.t('เกิดข้อผิดพลาดในการสร้างช่าง', 'Failed to create technician')),
                        backgroundColor: AppTheme.danger,
                      ),
                    );
                  }
                }
              },
              child: Text(_lang.t('สร้างบัญชีช่าง', 'Create Account')),
            ),
          ],
        );
      },
    );
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
                  '${_lang.t("มอบหมายงาน", "Assign Ticket")}: ${ticket.ticketNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 6),
                Text(
                  ticket.title,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                Text(
                  _lang.t('เลือกช่างเทคนิคที่พร้อมปฏิบัติงาน:', 'Select available technician:'),
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 8),
                if (_technicians.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        _lang.t('ไม่มีรายชื่อช่าง กรุณาเพิ่มช่างก่อน', 'No technicians found. Please add technicians.'),
                        style: const TextStyle(color: AppTheme.textMuted),
                      ),
                    ),
                  )
                else
                  ..._technicians.map((tech) {
                    final activeCount = tech['activeTicketsCount'] ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                        child: const Icon(Icons.handyman_rounded, color: AppTheme.primaryLight, size: 18),
                      ),
                      title: Text(tech['name'] ?? '', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                      subtitle: Text(
                        '${tech['username']} • ${tech['phone']}',
                        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: activeCount > 0 ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$activeCount ${_lang.t("งาน", "jobs")}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: activeCount > 0 ? AppTheme.warning : AppTheme.success,
                          ),
                        ),
                      ),
                      onTap: () {
                        context.read<TicketBloc>().add(
                              AssignTicketEvent(
                                ticketId: ticket.id,
                                technicianId: tech['id'] ?? '',
                                technicianName: tech['name'] ?? '',
                              ),
                            );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(_lang.t('มอบหมายงานให้ ${tech["name"]} สำเร็จ', 'Assigned to ${tech["name"]}')),
                            backgroundColor: AppTheme.success,
                          ),
                        );
                        _loadTechnicians();
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.dashboard_customize_outlined, color: AppTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _lang.t('แผงควบคุมระบบแอดมิน', 'Dispatcher Operations'),
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primary,
          indicatorWeight: 3,
          labelColor: AppTheme.primaryLight,
          unselectedLabelColor: AppTheme.textMuted,
          tabs: [
            Tab(
              icon: const Icon(Icons.confirmation_number_outlined, size: 20),
              text: _lang.t('ใบแจ้งซ่อม', 'Tickets Matrix'),
            ),
            Tab(
              icon: const Icon(Icons.people_alt_outlined, size: 20),
              text: _lang.t('จัดการช่างเทคนิค (${_technicians.length})', 'Technicians (${_technicians.length})'),
            ),
          ],
        ),
        actions: [
          // Language Switcher
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: _lang.t('รีเฟรช', 'Refresh'),
            onPressed: () {
              context.read<TicketBloc>().add(const FetchTicketsEvent(forceRefresh: true));
              _loadTechnicians();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: _lang.t('ออกจากระบบ', 'Logout'),
            onPressed: () => context.read<AuthBloc>().add(LogoutSubmittedEvent()),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: TICKETS MATRIX
          _buildTicketsTab(),

          // TAB 2: TECHNICIANS MANAGEMENT
          _buildTechniciansTab(),
        ],
      ),
    );
  }

  Widget _buildTicketsTab() {
    return BlocBuilder<TicketBloc, TicketState>(
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
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildChip('All', _lang.t('ทั้งหมด (${allTickets.length})', 'All (${allTickets.length})')),
                  const SizedBox(width: 8),
                  _buildChip('Pending', _lang.t('รอจ่ายงาน', 'Pending')),
                  const SizedBox(width: 8),
                  _buildChip('Assigned', _lang.t('จ่ายงานแล้ว', 'Assigned')),
                  const SizedBox(width: 8),
                  _buildChip('In Progress', _lang.t('กำลังซ่อม', 'In Progress')),
                  const SizedBox(width: 8),
                  _buildChip('Completed', _lang.t('เสร็จสิ้น', 'Completed')),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(child: Text(_lang.t('ไม่มีรายการตามเงื่อนไขที่เลือก', 'No tickets found'), style: const TextStyle(color: AppTheme.textMuted)))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final ticket = filtered[index];
                        return _buildTicketCard(ticket);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTicketCard(TicketEntity ticket) {
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
                    border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
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
                  ticket.assignedToName != null ? '${_lang.t("ช่าง", "Tech")}: ${ticket.assignedToName}' : _lang.t('ยังไม่ได้มอบหมาย', 'Unassigned'),
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
                    ticket.assignedToName != null ? _lang.t('เปลี่ยนช่าง', 'Reassign') : _lang.t('จ่ายงานให้ช่าง', 'Assign'),
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
  }

  Widget _buildTechniciansTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _lang.t('ทีมช่างเทคนิคประจำศูนย์', 'Technician Fleet'),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  Text(
                    _lang.t('ช่างทุกคนสามารถล็อกอินผ่านแอปมือถือด้วยบัญชีนี้', 'Technicians log in using these credentials'),
                    style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddTechnicianDialog,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(_lang.t('+ เพิ่มช่างใหม่', '+ Add Tech')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(0, 40),
                ),
              ),
            ],
          ),
        ),
        if (_isLoadingTechs)
          const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
        else if (_technicians.isEmpty)
          Expanded(
            child: Center(
              child: Text(
                _lang.t('ยังไม่มีช่างในระบบ กรุณากดปุ่ม + เพิ่มช่างใหม่', 'No technicians yet. Click + Add Tech.'),
                style: const TextStyle(color: AppTheme.textMuted),
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _technicians.length,
              itemBuilder: (context, idx) {
                final tech = _technicians[idx];
                final activeJobs = tech['activeTicketsCount'] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.handyman_rounded, color: AppTheme.primaryLight, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tech['name'] ?? '',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.card,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppTheme.border),
                                    ),
                                    child: Text(
                                      '@${tech['username']}',
                                      style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppTheme.primaryLight),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.phone_outlined, size: 12, color: AppTheme.textMuted),
                                  const SizedBox(width: 4),
                                  Text(tech['phone'] ?? '-', style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeJobs > 0 ? AppTheme.warning.withValues(alpha: 0.15) : AppTheme.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: activeJobs > 0 ? AppTheme.warning.withValues(alpha: 0.3) : AppTheme.success.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                activeJobs.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: activeJobs > 0 ? AppTheme.warning : AppTheme.success,
                                ),
                              ),
                              Text(
                                _lang.t('งานแอคทีฟ', 'Active'),
                                style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                              ),
                            ],
                          ),
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
