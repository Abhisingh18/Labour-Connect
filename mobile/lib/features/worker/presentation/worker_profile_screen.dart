import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/rating_stars.dart';
import '../../../core/widgets/states.dart';
import '../../../core/widgets/status_badge.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/worker_model.dart';
import 'worker_providers.dart';

class WorkerProfileScreen extends ConsumerWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final profile = ref.watch(workerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: profile.when(
        loading: () => const ListSkeleton(itemHeight: 120),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(workerProfileProvider),
        ),
        data: (p) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                children: [
                  Avatar(name: user?.name ?? 'Worker', imageUrl: user?.profileImage, size: 72),
                  const SizedBox(height: 12),
                  Text(user?.name ?? 'Worker',
                      style: AppText.h2.copyWith(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(p.category?.name ?? 'Set your skill',
                      style: AppText.label.copyWith(color: Colors.white70)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: RatingStars(rating: p.rating, count: p.ratingCount, size: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('Verification', style: AppText.title),
                  const Spacer(),
                  StatusBadge.forKyc(p.kycStatus),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(profile: p),
            const SizedBox(height: 16),
            _Tile(
              icon: Icons.edit_rounded,
              title: 'Edit work profile',
              onTap: () => context.push(Routes.workerEditProfile, extra: p),
            ),
            if (!p.isVerified)
              _Tile(
                icon: Icons.badge_rounded,
                title: 'KYC verification',
                onTap: () => context.push(Routes.workerKyc),
              ),
            _Tile(icon: Icons.help_outline_rounded, title: 'Help & support', onTap: () {}),
            const SizedBox(height: 8),
            _Tile(
              icon: Icons.logout_rounded,
              title: 'Log out',
              danger: true,
              onTap: () => _logout(context, ref),
            ),
            const SizedBox(height: 20),
            Center(child: Text('Labour Connect v1.0.0', style: AppText.caption)),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Log out?', style: AppText.h3),
        content: Text('You\'ll need to verify your number again.', style: AppText.body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Stay')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log out', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(authControllerProvider.notifier).logout();
  }
}

class _DetailCard extends StatelessWidget {
  final WorkerProfile profile;
  const _DetailCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Work details', style: AppText.h3),
          const SizedBox(height: 14),
          _row(Icons.home_repair_service_rounded, 'Service', profile.category?.name ?? '—'),
          _row(Icons.work_history_rounded, 'Experience', '${profile.experience} years'),
          _row(Icons.map_rounded, 'Service area', profile.serviceArea ?? '—'),
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _row(Icons.info_outline_rounded, 'Bio', profile.bio!, last: true),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool last = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Text(label, style: AppText.label),
          const SizedBox(width: 16),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right, style: AppText.bodyStrong),
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: danger ? AppColors.danger : AppColors.primary),
                const SizedBox(width: 14),
                Text(title, style: AppText.title.copyWith(color: color)),
                const Spacer(),
                if (!danger)
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
