// lib/features/home/presentation/widgets/common/user_avatar_widget.dart
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class UserAvatarWidget extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;

  const UserAvatarWidget({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.primaryBlue.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: CircleAvatar(
          backgroundImage: NetworkImage(imageUrl!),
          radius: size / 2,
        ),
      );
    }

    // Default avatar with initials
    final initials = _getInitials(name ?? 'مستخدم');

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppTheme.primaryBlue.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.length > 1
        ? name.substring(0, 2).toUpperCase()
        : name.toUpperCase();
  }
}
