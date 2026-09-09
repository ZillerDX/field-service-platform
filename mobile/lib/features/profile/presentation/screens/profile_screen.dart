import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/offline_cache.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AppLanguage _lang = AppLanguage();

  @override
  void initState() {
    super.initState();
    _lang.addListener(_onLangChange);
  }

  @override
  void dispose() {
    _lang.removeListener(_onLangChange);
    super.dispose();
  }

  void _onLangChange() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    String name = 'User';
    String email = 'user@fieldops.io';
    String role = 'technician';

    if (authState is Authenticated) {
      name = authState.user.name;
      email = authState.user.email ?? authState.user.username;
      role = authState.user.role;
    }

    final isTech = role.toLowerCase() == 'technician';

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
              context.go(isTech ? '/technician' : '/dispatcher');
            }
          },
        ),
        title: Text(
          _lang.t('ข้อมูลโปรไฟล์ & การตั้งค่า', 'Profile & Settings'),
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.2),
                    child: const Icon(Icons.person_rounded, size: 36, color: AppTheme.primaryLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primaryLight.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            isTech
                                ? _lang.t('ช่างบริการภาคสนาม (Field Technician)', 'Field Technician')
                                : _lang.t('ผู้ดูแลระบบ (System Admin)', 'System Admin'),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              _lang.t('การตั้งค่าภาษา / Language', 'Language Settings'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),

            // Language Switcher Options
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      _lang.isThai ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      color: _lang.isThai ? AppTheme.primaryLight : AppTheme.textMuted,
                    ),
                    title: const Text('ภาษาไทย (Thai)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: const Text('แสดงผลข้อความภาษาไทยเป็นค่าเริ่มต้น', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    onTap: () => _lang.setLanguage('th'),
                  ),
                  const Divider(height: 1, color: AppTheme.border),
                  ListTile(
                    leading: Icon(
                      !_lang.isThai ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                      color: !_lang.isThai ? AppTheme.primaryLight : AppTheme.textMuted,
                    ),
                    title: const Text('English', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14)),
                    subtitle: const Text('Display system in English interface', style: TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                    onTap: () => _lang.setLanguage('en'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Text(
              _lang.t('ระบบและเครือข่าย / System & Network', 'System & Network'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lang.t('เซิร์ฟเวอร์ปลายทาง', 'API Endpoint'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      Text(
                        DioClient.resolveBaseUrl(),
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace', color: AppTheme.primaryLight),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lang.t('เวอร์ชันระบบ', 'App Version'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      const Text(
                        'v1.1.0 (Production Release)',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: AppTheme.border),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _lang.t('พื้นที่จัดเก็บออฟไลน์', 'Offline Cache'),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                      ),
                      TextButton(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          await OfflineCache.clearAll();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(_lang.t('ล้างแคชออฟไลน์สำเร็จ', 'Offline cache cleared successfully')),
                              backgroundColor: AppTheme.success,
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 30),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          _lang.t('ล้างแคช', 'Clear Cache'),
                          style: const TextStyle(color: AppTheme.warning, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            // Logout Button
            OutlinedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: AppTheme.surface,
                    title: Text(
                      _lang.t('ยืนยันออกจากระบบ', 'Confirm Logout'),
                      style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
                    ),
                    content: Text(
                      _lang.t('คุณต้องการออกจากระบบ FieldOps Nexus หรือไม่?', 'Are you sure you want to log out of FieldOps Nexus?'),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(_lang.t('ยกเลิก', 'Cancel'), style: const TextStyle(color: AppTheme.textMuted)),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthBloc>().add(LogoutSubmittedEvent());
                          context.go('/login');
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
                        child: Text(_lang.t('ออกจากระบบ', 'Log Out')),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout_rounded, color: AppTheme.danger, size: 20),
              label: Text(
                _lang.t('ออกจากระบบ (Log Out)', 'Log Out'),
                style: const TextStyle(color: AppTheme.danger, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.danger),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
