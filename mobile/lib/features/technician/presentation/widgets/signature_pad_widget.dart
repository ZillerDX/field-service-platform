import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:field_service_mobile/core/theme/app_theme.dart';

class SignaturePadWidget extends StatefulWidget {
  final Function(String? signature) onSignatureChanged;

  const SignaturePadWidget({super.key, required this.onSignatureChanged});

  @override
  State<SignaturePadWidget> createState() => _SignaturePadWidgetState();
}

class _SignaturePadWidgetState extends State<SignaturePadWidget> {
  final List<Offset?> _points = [];
  bool _isSigned = false;

  void _clear() {
    setState(() {
      _points.clear();
      _isSigned = false;
    });
    widget.onSignatureChanged(null);
  }

  void _confirm() {
    if (_points.isNotEmpty) {
      setState(() {
        _isSigned = true;
      });
      final sigId = 'sig_${DateTime.now().millisecondsSinceEpoch}';
      widget.onSignatureChanged(sigId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกลายเซ็นลูกค้าเรียบร้อยแล้ว')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isSigned ? AppTheme.success.withValues(alpha: 0.6) : AppTheme.border,
          width: _isSigned ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.draw_outlined, color: AppTheme.primaryLight, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'ลายมือชื่อลูกค้ารับมอบงาน (Sign-off)',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14),
                  ),
                ],
              ),
              if (_isSigned)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'ลงนามแล้ว',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Interactive Canvas
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: RawGestureDetector(
                gestures: {
                  PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                    () => PanGestureRecognizer(),
                    (PanGestureRecognizer instance) {
                      instance.onStart = (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      };
                      instance.onUpdate = (details) {
                        setState(() {
                          _points.add(details.localPosition);
                        });
                      };
                      instance.onEnd = (details) {
                        setState(() {
                          _points.add(null);
                        });
                      };
                    },
                  ),
                },
                child: CustomPaint(
                  painter: _SignaturePainter(points: _points),
                  size: Size.infinite,
                  child: Center(
                    child: _points.isEmpty
                        ? const Text(
                            'ลากนิ้วหรือปากกาเพื่อเซ็นชื่อที่นี่',
                            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.clear, size: 16, color: AppTheme.textSecondary),
                label: const Text('ล้างลายเซ็น', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _points.isEmpty ? null : _confirm,
                icon: const Icon(Icons.check, size: 16),
                label: const Text('ยืนยันลายเซ็น', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  _SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6366F1)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
