import 'package:flutter/material.dart';
import 'package:mobile/core/constants/app_colors.dart';

class SettingsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const SettingsSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (onChanged != null) {
          onChanged!(!value);
        }
      },
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: value
              ? AppColors.primaryBrown.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.primaryBrown,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
