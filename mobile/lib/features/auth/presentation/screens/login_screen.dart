import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:field_service_mobile/features/auth/presentation/bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController(text: 'tech_vichai');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final u = _usernameController.text.trim();
    final p = _passwordController.text.trim();
    if (u.isNotEmpty && p.isNotEmpty) {
      context.read<AuthBloc>().add(LoginSubmittedEvent(username: u, password: p));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: BlocConsumer<AuthBloc, AuthState>(
              listener: (context, state) {
                if (state is AuthFailure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.message),
                      backgroundColor: AppTheme.danger,
                    ),
                  );
                }
              },
              builder: (context, state) {
                final isLoading = state is AuthLoading;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Vector Monogram
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.25),
                              blurRadius: 24,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          color: AppTheme.primaryLight,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'FieldOps Nexus',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Enterprise Field Service & Maintenance Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Inputs Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _usernameController,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: const InputDecoration(
                              labelText: 'ชื่อผู้ใช้ / Username',
                              prefixIcon: Icon(Icons.person_outline, color: AppTheme.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: AppTheme.textPrimary),
                            decoration: InputDecoration(
                              labelText: 'รหัสผ่าน / Password',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.textSecondary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            child: isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Text('เข้าสู่ระบบ / Sign In'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'เข้าสู่ระบบด่วนสำหรับการทดสอบ',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Quick Demo Buttons
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildRoleChip(
                          context,
                          label: 'ช่างวิชัย (Technician)',
                          icon: Icons.handyman_outlined,
                          role: 'technician',
                        ),
                        _buildRoleChip(
                          context,
                          label: 'แอดมินสมศรี (Dispatcher)',
                          icon: Icons.admin_panel_settings_outlined,
                          role: 'admin',
                        ),
                        _buildRoleChip(
                          context,
                          label: 'ลูกค้าสมชาย (Customer)',
                          icon: Icons.person_outline,
                          role: 'customer',
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleChip(BuildContext context, {required String label, required IconData icon, required String role}) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppTheme.primaryLight),
      label: Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textPrimary)),
      backgroundColor: AppTheme.surface,
      side: const BorderSide(color: AppTheme.border),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      onPressed: () {
        context.read<AuthBloc>().add(QuickDemoLoginEvent(role));
      },
    );
  }
}
