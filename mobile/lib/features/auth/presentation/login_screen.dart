import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final String role;
  const LoginScreen({super.key, required this.role});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  bool _loading = false;

  bool get _isWorker => widget.role == 'worker';

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final phone = _phone.text.trim();
      final devOtp = await ref.read(authControllerProvider.notifier).sendOtp(phone);
      if (!mounted) return;
      context.push(
        Routes.otp,
        extra: {'phone': phone, 'role': widget.role, 'devOtp': devOtp},
      );
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _isWorker ? AppColors.accent : AppColors.primary;
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isWorker ? Icons.engineering_rounded : Icons.person_rounded,
                    color: accent,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _isWorker ? 'Worker login' : 'Let\'s get started',
                  style: AppText.h1,
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your mobile number. We\'ll send you a one-time password to verify.',
                  style: AppText.body,
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _phone,
                  label: 'Mobile number',
                  hint: '10-digit number',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  validator: Validators.phone,
                  maxLength: 10,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: 'Send OTP',
                  icon: Icons.arrow_forward_rounded,
                  loading: _loading,
                  onPressed: _sendOtp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
