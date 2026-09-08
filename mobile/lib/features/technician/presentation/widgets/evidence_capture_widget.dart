import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class EvidenceCaptureWidget extends StatefulWidget {
  final Function(String? before, String? after) onEvidenceChanged;

  const EvidenceCaptureWidget({super.key, required this.onEvidenceChanged});

  @override
  State<EvidenceCaptureWidget> createState() => _EvidenceCaptureWidgetState();
}

class _EvidenceCaptureWidgetState extends State<EvidenceCaptureWidget> {
  String? _beforePhoto;
  String? _afterPhoto;

  void _simulateCaptureBefore() {
    setState(() {
      _beforePhoto = 'evidence_before_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    widget.onEvidenceChanged(_beforePhoto, _afterPhoto);
  }

  void _simulateCaptureAfter() {
    setState(() {
      _afterPhoto = 'evidence_after_${DateTime.now().millisecondsSinceEpoch}.jpg';
    });
    widget.onEvidenceChanged(_beforePhoto, _afterPhoto);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt_outlined, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text(
                'ภาพถ่ายหลักฐานหน้างาน (Job Evidence)',
                style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPhotoBox(
                  title: 'ก่อนซ่อม (Before)',
                  photoUrl: _beforePhoto,
                  onCapture: _simulateCaptureBefore,
                  onClear: () {
                    setState(() => _beforePhoto = null);
                    widget.onEvidenceChanged(_beforePhoto, _afterPhoto);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPhotoBox(
                  title: 'หลังซ่อม (After)',
                  photoUrl: _afterPhoto,
                  onCapture: _simulateCaptureAfter,
                  onClear: () {
                    setState(() => _afterPhoto = null);
                    widget.onEvidenceChanged(_beforePhoto, _afterPhoto);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoBox({
    required String title,
    required String? photoUrl,
    required VoidCallback onCapture,
    required VoidCallback onClear,
  }) {
    final hasPhoto = photoUrl != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        const SizedBox(height: 6),
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: hasPhoto ? AppTheme.success : AppTheme.border),
          ),
          child: hasPhoto
              ? Stack(
                  children: [
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppTheme.success, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            photoUrl,
                            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: onClear,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppTheme.surface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, size: 14, color: AppTheme.danger),
                        ),
                      ),
                    ),
                  ],
                )
              : Center(
                  child: TextButton.icon(
                    onPressed: onCapture,
                    icon: const Icon(Icons.add_a_photo_outlined, size: 18),
                    label: const Text('ถ่ายภาพ', style: TextStyle(fontSize: 12)),
                  ),
                ),
        ),
      ],
    );
  }
}
