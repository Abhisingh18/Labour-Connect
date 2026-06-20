import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/config/env.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/utils/validators.dart';
import 'auth_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String role;
  final String? devOtp;

  const OtpScreen({
    super.key,
    required this.phone,
    required this.role,
    this.devOtp,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otp = TextEditingController();
  final _name = TextEditingController();
  bool _loading = false;
  int _seconds = 30;
  Timer? _timer;

  bool get _isWorker => widget.role == 'worker';

  @override
  void initState() {
    super.initState();
    if (Env.showDevOtpHint && widget.devOtp != null) {
      _otp.text = widget.devOtp!;
    }
    _startTimer();
  }

  void _startTimer() {
    _seconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds == 0) {
        t.cancel();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otp.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_otp.text.trim().length < 4) {
      showSnack(context, 'Enter the 6-digit OTP', error: true);
      return;
    }
    final nameError = Validators.name(_name.text);
    if (nameError != null) {
      showSnack(context, nameError, error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await ref.read(authControllerProvider.notifier).verifyOtp(
            phone: widget.phone,
            otp: _otp.text.trim(),
            role: widget.role,
            name: _name.text.trim(),
          );
      // Router redirect handles navigation to the correct home.
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      await ref.read(authControllerProvider.notifier).sendOtp(widget.phone);
      _startTimer();
      if (mounted) showSnack(context, 'OTP resent');
    } catch (e) {
      if (mounted) showSnack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your number', style: AppText.h1),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  style: AppText.body,
                  children: [
                    const TextSpan(text: 'Enter the OTP sent to '),
                    TextSpan(
                      text: '+91 ${widget.phone}',
                      style: AppText.bodyStrong,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otp,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                enableActiveFill: true,
                cursorColor: AppColors.primary,
                textStyle: AppText.h2,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(14),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  activeFillColor: AppColors.primaryLight,
                  selectedFillColor: AppColors.surface,
                  inactiveFillColor: AppColors.surface,
                ),
                onChanged: (_) {},
              ),
              if (Env.showDevOtpHint && widget.devOtp != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          size: 18, color: AppColors.info),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dev mode: OTP is ${widget.devOtp}',
                          style: AppText.caption.copyWith(color: AppColors.info),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),
              AppTextField(
                controller: _name,
                label: 'Your name',
                hint: _isWorker ? 'As per your ID' : 'Full name',
                prefixIcon: Icons.badge_rounded,
              ),
              const SizedBox(height: 12),
              Text(
                'New here? We\'ll create your account automatically.',
                style: AppText.caption,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify & Continue',
                loading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 16),
              Center(
                child: _seconds > 0
                    ? Text('Resend OTP in 0:${_seconds.toString().padLeft(2, '0')}',
                        style: AppText.label)
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend OTP'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
