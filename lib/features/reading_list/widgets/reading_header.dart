import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile/core/brand/site_brand.dart';
import 'package:mobile/core/constants/app_colors.dart';

class ReadingHeader extends StatelessWidget {
  const ReadingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const EditorialPageHeader(
            title: 'Thư viện',
            subtitle:
                'Sách, danh sách đọc và hành trình văn chương của bạn trên Nook.',
            padding: EdgeInsets.zero,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTab('Thư viện', isActive: true),
              _buildTab('Muốn đọc'),
              _buildTab('Đang đọc'),
              _buildTab('Đã đọc'),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Sắp xếp: Gần đây',
              style: GoogleFonts.inter(
                color: AppColors.homeTextDark,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTab(String label, {bool isActive = false}) {
    return Text(
      label,
      style: GoogleFonts.inter(
        color: isActive ? AppColors.primaryBrown : AppColors.homeTextLight,
        fontSize: 13,
        fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}
