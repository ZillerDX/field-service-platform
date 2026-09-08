import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class SparePartsWidget extends StatefulWidget {
  final Function(List<Map<String, dynamic>> parts) onPartsChanged;

  const SparePartsWidget({super.key, required this.onPartsChanged});

  @override
  State<SparePartsWidget> createState() => _SparePartsWidgetState();
}

class _SparePartsWidgetState extends State<SparePartsWidget> {
  final List<Map<String, dynamic>> _parts = [];
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '0');

  void _addPart() {
    final name = _nameCtrl.text.trim();
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;

    if (name.isNotEmpty && qty > 0) {
      setState(() {
        _parts.add({
          'name': name,
          'quantity': qty,
          'unitPrice': price,
          'total': qty * price,
        });
        _nameCtrl.clear();
        _qtyCtrl.text = '1';
        _priceCtrl.text = '0';
      });
      widget.onPartsChanged(_parts);
    }
  }

  void _removePart(int index) {
    setState(() {
      _parts.removeAt(index);
    });
    widget.onPartsChanged(_parts);
  }

  @override
  Widget build(BuildContext context) {
    double grandTotal = 0;
    for (var p in _parts) {
      grandTotal += (p['total'] as num).toDouble();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
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
                  Icon(Icons.inventory_2_outlined, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'บันทึกการเบิกใช้อะไหล่ (Spare Parts)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ],
              ),
              if (_parts.isNotEmpty)
                Text(
                  'รวม ฿${grandTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.success, fontSize: 14),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Add row input
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ชื่ออะไหล่ / อุปกรณ์',
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'จำนวน',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'ราคา/หน่วย',
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: _addPart,
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryLight),
                tooltip: 'เพิ่มรายการ',
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_parts.isNotEmpty) ...[
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _parts.length,
              itemBuilder: (context, idx) {
                final p = _parts[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${idx + 1}. ', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                      Expanded(
                        child: Text(
                          p['name'],
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                      Text(
                        'x${p['quantity']} (฿${(p['total'] as num).toStringAsFixed(0)})',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppTheme.danger),
                        onPressed: () => _removePart(idx),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
