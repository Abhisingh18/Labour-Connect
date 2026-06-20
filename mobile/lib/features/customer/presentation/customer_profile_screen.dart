import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/primary_button.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/presentation/auth_controller.dart';

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Avatar(
                  name: user?.name ?? 'You',
                  imageUrl: user?.profileImage,
                  size: 64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user?.name ?? 'You',
                          style: AppText.h2.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      Text('+91 ${user?.phone ?? ''}',
                          style: AppText.label.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _editProfile(context, ref),
                  icon: const Icon(Icons.edit_rounded, color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _Tile(
            icon: Icons.edit_rounded,
            title: 'Edit profile',
            onTap: () => _editProfile(context, ref),
          ),
          _Tile(icon: Icons.help_outline_rounded, title: 'Help & support', onTap: () {}),
          _Tile(icon: Icons.privacy_tip_outlined, title: 'Privacy policy', onTap: () {}),
          _Tile(icon: Icons.info_outline_rounded, title: 'About', onTap: () {}),
          const SizedBox(height: 12),
          _Tile(
            icon: Icons.logout_rounded,
            title: 'Log out',
            danger: true,
            onTap: () => _logout(context, ref),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Labour Connect v1.0.0', style: AppText.caption)),
        ],
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    final user = ref.read(authControllerProvider).user;
    final controller = TextEditingController(text: user?.name);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Edit profile', style: AppText.h2),
            const SizedBox(height: 20),
            AppTextField(
              controller: controller,
              label: 'Full name',
              prefixIcon: Icons.person_rounded,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                try {
                  final updated = await ref
                      .read(authRepositoryProvider)
                      .updateProfile(name: controller.text.trim());
                  ref.read(authControllerProvider.notifier).setUser(updated);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } catch (e) {
                  if (ctx.mounted) showSnack(ctx, e.toString(), error: true);
                }
              },
            ),
          ],
        ),
      ),
    );
    if (saved == true && context.mounted) {
      showSnack(context, 'Profile updated');
    }
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
