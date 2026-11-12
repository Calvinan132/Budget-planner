import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Avatar người dùng dùng đồng bộ trên mọi màn hình.
/// Hiển thị ảnh Google/Facebook nếu có, ngược lại hiện chữ abbreviated của tên.
class UserAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? displayName;
  final double radius;

  const UserAvatar({
    super.key,
    this.photoUrl,
    this.displayName,
    this.radius = 24,
  });

  String _initials(String? name) {
    if (name == null || name.isEmpty) return 'U';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = photoUrl != null && photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primaryLight,
      backgroundImage: hasImage ? NetworkImage(photoUrl!) : null,
      child: hasImage
          ? null
          : Text(
              _initials(displayName),
              style: AppTextStyles.headingLarge(color: AppColors.primaryDark).copyWith(
                fontSize: radius * 0.5,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
