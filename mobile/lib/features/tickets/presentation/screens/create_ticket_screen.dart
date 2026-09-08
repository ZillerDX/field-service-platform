import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_bloc.dart';
import 'package:field_service_mobile/features/tickets/presentation/bloc/ticket_event.dart';

class CreateTicketScreen extends StatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  State<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends State<CreateTicketScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _customerNameController = TextEditingController(text: 'คุณสมชาย สถิตย์วงศ์');
  final _phoneController = TextEditingController(text: '089-123-4567');
  final _locationNameController = TextEditingController(text: 'สำนักงานสาทร อาคารเอเชีย ชั้น 12');

  String _selectedCategory = 'HVAC';
  String _selectedUrgency = 'Medium';
  double _latitude = 13.7214;
  double _longitude = 100.5298;
  bool _isLocating = false;

  final List<String> _categories = ['HVAC', 'Electrical', 'Plumbing', 'Network', 'General'];
  final List<String> _urgencies = ['Low', 'Medium', 'High', 'Emergency'];

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _customerNameController.dispose();
    _phoneController.dispose();
    _locationNameController.dispose();
    super.dispose();
  }

  void _setCurrentLocation() {
    setState(() {
      _isLocating = true;
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _latitude = 13.7563;
          _longitude = 100.5018;
          _locationNameController.text = 'พิกัดปัจจุบัน (เขตพระนคร, กรุงเทพฯ)';
          _isLocating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ดึงพิกัด GPS ปัจจุบันสำเร็จ')),
        );
      }
    });
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<TicketBloc>().add(
            CreateTicketEvent(
              title: _titleController.text.trim(),
              description: _descController.text.trim(),
              category: _selectedCategory,
              urgency: _selectedUrgency,
              lat: _latitude,
              lon: _longitude,
              locationName: _locationNameController.text.trim(),
              customerName: _customerNameController.text.trim(),
              customerPhone: _phoneController.text.trim(),
            ),
          );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกใบแจ้งซ่อมสำเร็จ'),
          backgroundColor: AppTheme.success,
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('สร้างใบแจ้งซ่อมใหม่'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category
              const Text(
                'หมวดหมู่งานซ่อม / Category',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = cat);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Urgency
              const Text(
                'ระดับความเร่งด่วน / Urgency',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _urgencies.map((urg) {
                  final isSelected = _selectedUrgency == urg;
                  Color activeColor = AppTheme.primary;
                  if (urg == 'Emergency') activeColor = AppTheme.danger;
                  if (urg == 'High') activeColor = AppTheme.warning;

                  return ChoiceChip(
                    label: Text(urg),
                    selected: isSelected,
                    selectedColor: activeColor,
                    backgroundColor: AppTheme.surface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedUrgency = urg);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Title & Description
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'หัวข้อปัญหา / Title *',
                  hintText: 'เช่น แอร์ห้องประชุมน้ำหยด, ท่อประปารั่ว',
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณากรอกหัวข้อ' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  labelText: 'รายละเอียดปัญหา / Description *',
                  hintText: 'อธิบายอาการหรือจุดสังเกตเพื่อช่วยให้ช่างเตรียมอุปกรณ์ได้ตรงจุด',
                ),
                validator: (val) => (val == null || val.trim().isEmpty) ? 'กรุณากรอกรายละเอียด' : null,
              ),
              const SizedBox(height: 20),

              // Location Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.pin_drop_outlined, size: 20, color: AppTheme.primaryLight),
                            SizedBox(width: 6),
                            Text(
                              'พิกัดและสถานที่เกิดเหตุ',
                              style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: _isLocating ? null : _setCurrentLocation,
                          icon: _isLocating
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight),
                                )
                              : const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('GPS ปัจจุบัน', style: TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _locationNameController,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        labelText: 'ชื่อสถานที่ / Location Name',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'พิกัดดาวเทียม: Lat ${_latitude.toStringAsFixed(4)}, Lon ${_longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textMuted, fontFamily: 'monospace'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                child: const Text('ยืนยันสร้างใบแจ้งซ่อม'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
