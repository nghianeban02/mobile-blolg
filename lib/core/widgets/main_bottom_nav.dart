import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/constants/app_colors.dart';

/// Centralized bottom navigation bar for the main tab shell.
class MainBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onIndexChanged;
  final bool showCreateButton;
  final VoidCallback? onCreateTap;

  const MainBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onIndexChanged,
    this.showCreateButton = false,
    this.onCreateTap,
  });

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.home_filled, label: 'HOME'),
    (icon: Icons.search_rounded, label: 'SEARCH'),
    (icon: Icons.library_books_outlined, label: 'LIBRARY'),
    (icon: Icons.settings_outlined, label: 'SETTINGS'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.homeBackground,
        border: Border(
          top: BorderSide(
            color: Colors.black.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: showCreateButton ? 72 : 64,
          child: showCreateButton
              ? Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        children: [
                          Expanded(child: _tab(0)),
                          Expanded(child: _tab(1)),
                          const SizedBox(width: 56),
                          Expanded(child: _tab(2)),
                          Expanded(child: _tab(3)),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 0,
                      child: _CreateCenterButton(onTap: onCreateTap),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(_items.length, (i) => _tab(i)),
                ),
        ),
      ),
    );
  }

  Widget _tab(int index) {
    final item = _items[index];
    return _NavItem(
      icon: item.icon,
      label: item.label,
      isSelected: index == currentIndex,
      onTap: () {
        if (index == currentIndex) return;
        onIndexChanged?.call(index);
      },
    );
  }
}

class _CreateCenterButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _CreateCenterButton({this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryBrown,
      elevation: 4,
      shadowColor: AppColors.primaryBrown.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
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
    final color = isSelected
        ? AppColors.primaryBrown
        : AppColors.homeTextLight.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppColors.primaryBrown.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  )
                : null,
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: color,
              fontSize: 8,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
