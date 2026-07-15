import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Bottom nav đồng bộ web (mobile-nav): 5 mục
/// Home · Search · Write (nút nâu tròn nổi bật) · Library · Me,
/// nền glass mờ + viền trên mảnh, label 10px.
class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool showCreateButton;
  final VoidCallback? onCreateTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onIndexChanged,
    this.showCreateButton = true,
    this.onCreateTap,
  });

  static const _items = <({IconData icon, IconData activeIcon, String label})>[
    (
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    (
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Search',
    ),
    (
      icon: Icons.auto_stories_outlined,
      activeIcon: Icons.auto_stories_rounded,
      label: 'Library',
    ),
    (
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Me',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = (isDark ? AppColors.darkBackground : AppColors.surface)
        .withValues(alpha: 0.85);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: barColor,
            border: Border(top: BorderSide(color: borderColor)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              height: 60,
              child: Row(
                children: [
                  Expanded(child: _tab(context, 0)),
                  Expanded(child: _tab(context, 1)),
                  Expanded(child: _WriteButton(onTap: onCreateTap)),
                  Expanded(child: _tab(context, 2)),
                  Expanded(child: _tab(context, 3)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final item = _items[index];
    final selected = index == currentIndex;
    return _NavItem(
      icon: selected ? item.activeIcon : item.icon,
      label: item.label,
      isSelected: selected,
      onTap: () {
        if (index == currentIndex) return;
        onIndexChanged?.call(index);
      },
    );
  }
}

/// Nút Write ở giữa — vòng tròn nâu nổi giống web mobile-nav.
class _WriteButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _WriteButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppShadows.primaryButton,
          ),
          child: Material(
            color: AppColors.primaryBrown,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.add_rounded, color: Colors.white, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Write',
          style: GoogleFonts.inter(
            color: AppColors.primaryBrown,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? AppColors.darkAccent : AppColors.primaryBrown;
    final inactiveColor = isDark
        ? AppColors.darkMuted
        : AppColors.homeTextLight;
    final color = isSelected ? activeColor : inactiveColor;

    return InkWell(
      onTap: onTap,
      customBorder: const StadiumBorder(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: AppRadius.pill,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
