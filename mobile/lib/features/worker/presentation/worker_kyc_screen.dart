import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/primary_button.dart';
import '../data/worker_repository.dart';
import 'worker_providers.dart';

/// KYC document upload.
///
/// NOTE: The backend stores document *URLs*. A production build should upload
/// the picked file to object storage (S3 / Firebase Storage / Cloudinary) and
/// send back the resulting URL. For the MVP we send a stand-in URL derived from
/// the file name so the verification flow works end-to-end.
class WorkerKycScreen extends ConsumerStatefulWidget {
  const WorkerKycScreen({super.key});

  @override
  ConsumerState<WorkerKycScreen> createState() => _State();
}

class _State extends ConsumerState<WorkerKycScreen> {
  final _picker = ImagePicker();
  File? _aadhaar;
  File? _pan;
  File? _selfie;
  bool _busy = false;

  Future<void> _pick(void Function(File) onPicked) async {
    final x = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (x != null) setState(() => onPicked(File(x.path)));
  }

  Future<void> _submit() async {
    if (_aadhaar == null || _selfie == null) {
      showSnack(context, 'Aadhaar and selfie are required', error: true);
      return;
    }
    setState(() => _busy = true);
    try {
      final repo = ref.read(workerRepositoryProvider);
      // Upload each document to the secure endpoint, then save the returned URLs.
      final aadhaarUrl = await repo.uploadKycFile(_aadhaar!.path);
      final selfieUrl = await repo.uploadKycFile(_selfie!.path);
      final panUrl = _pan == null ? null : await repo.uploadKycFile(_pan!.path);

      await repo.submitKyc(
        aadhaarUrl: aadhaarUrl,
        panUrl: panUrl,
        selfieUrl: selfieUrl,
      );
      ref.invalidate(workerProfileProvider);
      if (!mounted) return;
      showSnack(context, 'KYC submitted for review');
      context.pop();
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC verification')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Verify your identity', style: AppText.h1),
          const SizedBox(height: 8),
          Text(
            'Upload clear photos of your documents. Verification usually takes less than 24 hours.',
            style: AppText.body,
          ),
          const SizedBox(height: 24),
          _UploadTile(
            title: 'Aadhaar card',
            subtitle: 'Front side, all corners visible',
            required: true,
            file: _aadhaar,
            onTap: () => _pick((f) => _aadhaar = f),
          ),
          const SizedBox(height: 14),
          _UploadTile(
            title: 'PAN card',
            subtitle: 'Optional but recommended',
            required: false,
            file: _pan,
            onTap: () => _pick((f) => _pan = f),
          ),
          const SizedBox(height: 14),
          _UploadTile(
            title: 'Selfie',
            subtitle: 'A clear photo of your face',
            required: true,
            file: _selfie,
            onTap: () => _pick((f) => _selfie = f),
          ),
          const SizedBox(height: 28),
          PrimaryButton(
            label: 'Submit for verification',
            loading: _busy,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool required;
  final File? file;
  final VoidCallback onTap;

  const _UploadTile({
    required this.title,
    required this.subtitle,
    required this.required,
    required this.file,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final done = file != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: done ? AppColors.success : AppColors.border,
            width: done ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: done ? AppColors.successLight : AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              clipBehavior: Clip.antiAlias,
              child: done
                  ? Image.file(file!, fit: BoxFit.cover)
                  : const Icon(Icons.add_photo_alternate_rounded,
                      color: AppColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: AppText.h3.copyWith(fontSize: 15)),
                      if (required) ...[
                        const SizedBox(width: 4),
                        const Text('*', style: TextStyle(color: AppColors.danger)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppText.caption),
                ],
              ),
            ),
            Icon(
              done ? Icons.check_circle_rounded : Icons.upload_rounded,
              color: done ? AppColors.success : AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
