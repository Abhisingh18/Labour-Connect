import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/states.dart';
import '../../customer/presentation/customer_providers.dart';
import '../../shared/models/worker_model.dart';
import '../data/worker_repository.dart';
import 'worker_providers.dart';

class WorkerEditProfileScreen extends ConsumerStatefulWidget {
  final WorkerProfile profile;
  const WorkerEditProfileScreen({super.key, required this.profile});

  @override
  ConsumerState<WorkerEditProfileScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerEditProfileScreen> {
  late final _experience =
      TextEditingController(text: widget.profile.experience.toString());
  late final _bio = TextEditingController(text: widget.profile.bio ?? '');
  late final _area = TextEditingController(text: widget.profile.serviceArea ?? '');
  late int? _categoryId = widget.profile.categoryId;
  bool _busy = false;

  @override
  void dispose() {
    _experience.dispose();
    _bio.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_categoryId == null) {
      showSnack(context, 'Please choose your main skill', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref.read(workerRepositoryProvider).updateProfile(
            categoryId: _categoryId,
            experience: int.tryParse(_experience.text.trim()) ?? 0,
            bio: _bio.text.trim(),
            serviceArea: _area.text.trim(),
          );
      ref.invalidate(workerProfileProvider);
      if (!mounted) return;
      showSnack(context, 'Profile updated');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit work profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Your main skill', style: AppText.h3),
          const SizedBox(height: 12),
          categories.when(
            loading: () => const ShimmerBox(height: 50, radius: 16),
            error: (e, _) => Text(e.toString(), style: AppText.body),
            data: (cats) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: cats.map((c) {
                final selected = c.id == _categoryId;
                return ChoiceChip(
                  label: Text(c.name),
                  selected: selected,
                  showCheckmark: false,
                  labelStyle: AppText.label.copyWith(
                    color: selected ? Colors.white : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  selectedColor: AppColors.primary,
                  onSelected: (_) => setState(() => _categoryId = c.id),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 24),
          AppTextField(
            controller: _experience,
            label: 'Years of experience',
            prefixIcon: Icons.work_history_rounded,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _area,
            label: 'Service area',
            hint: 'e.g. Sector 21, Gurugram',
            prefixIcon: Icons.map_rounded,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _bio,
            label: 'About you',
            hint: 'Tell customers about your work and specialities',
            maxLines: 4,
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Save changes', loading: _busy, onPressed: _save),
        ],
      ),
    );
  }
}
