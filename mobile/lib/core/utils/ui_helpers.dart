import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Maps backend category icon keys / names to Material icons.
IconData categoryIcon(String? key) {
  switch ((key ?? '').toLowerCase()) {
    case 'plumbing':
    case 'plumber':
      return Icons.plumbing_rounded;
    case 'electrical':
    case 'electrician':
      return Icons.electrical_services_rounded;
    case 'carpenter':
      return Icons.handyman_rounded;
    case 'painter':
      return Icons.format_paint_rounded;
    case 'mason':
      return Icons.foundation_rounded;
    case 'labour':
      return Icons.engineering_rounded;
    case 'ac':
    case 'ac repair':
      return Icons.ac_unit_rounded;
    case 'appliance':
    case 'appliance repair':
      return Icons.kitchen_rounded;
    case 'cleaning':
      return Icons.cleaning_services_rounded;
    case 'driver':
      return Icons.local_taxi_rounded;
    case 'movers':
    case 'packers & movers':
      return Icons.local_shipping_rounded;
    default:
      return Icons.home_repair_service_rounded;
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              error ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
              color: error ? AppColors.dangerLight : AppColors.successLight,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.bodyStrong.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
}
