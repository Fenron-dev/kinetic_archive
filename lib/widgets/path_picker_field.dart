import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

/// Input field with a Browse/Connect button for path selection.
/// Uses surfaceContainerLowest for a "recessed" look.
class PathPickerField extends StatelessWidget {
  const PathPickerField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.buttonLabel = 'BROWSE',
    this.pickDirectory = true,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final String buttonLabel;
  final bool pickDirectory;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  Future<void> _pick() async {
    if (pickDirectory) {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        controller.text = result;
        onChanged?.call(result);
      }
    } else {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path ?? '';
        controller.text = path;
        onChanged?.call(path);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: KaTextStyles.labelLarge.copyWith(color: KaColors.onSurfaceVariant)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                enabled: enabled,
                readOnly: true,
                style: KaTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: hint,
                  filled: true,
                  fillColor: KaColors.surfaceContainerLowest,
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: const OutlineInputBorder(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomLeft: Radius.circular(12),
                    ),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 1),
            GestureDetector(
              onTap: enabled ? _pick : null,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: const BoxDecoration(
                  color: KaColors.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    buttonLabel,
                    style: KaTextStyles.labelLarge.copyWith(
                      color: KaColors.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
