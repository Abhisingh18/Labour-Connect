import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 28),
              Text('Welcome to\nLabour Connect', style: AppText.display),
              const SizedBox(height: 10),
              Text(
                'How would you like to continue?',
                style: AppText.body,
              ),
              const SizedBox(height: 36),
              _RoleCard(
                icon: Icons.person_search_rounded,
                title: 'I need a service',
                subtitle: 'Find & book trusted plumbers, electricians, cleaners and more',
                color: AppColors.primary,
                onTap: () => context.push('${Routes.login}?role=customer'),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
              _RoleCard(
                icon: Icons.engineering_rounded,
                title: 'I am a worker',
                subtitle: 'Get job requests near you and grow your earnings',
                color: AppColors.accent,
                onTap: () => context.push('${Routes.login}?role=worker'),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
              const Spacer(),
              Center(
                child: Text(
                  'By continuing you agree to our Terms & Privacy Policy',
                  style: AppText.caption,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.h3),
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppText.label, maxLines: 2),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded,
                  size: 16, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
