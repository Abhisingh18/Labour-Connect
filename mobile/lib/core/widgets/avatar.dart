import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/formatters.dart';

/// Circular avatar that shows a network image, or colored initials fallback.
class Avatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;

  const Avatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
  });

  Color get _bg {
    final idx = name.isEmpty ? 0 : name.codeUnitAt(0) % AppColors.avatarPalette.length;
    return AppColors.avatarPalette[idx];
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _fallback(),
          errorWidget: (_, __, ___) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _bg.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        Formatters.initials(name),
        style: AppText.h3.copyWith(color: _bg, fontSize: size * 0.34),
      ),
    );
  }
}
