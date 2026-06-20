import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';

class LabourConnectApp extends ConsumerStatefulWidget {
  const LabourConnectApp({super.key});

  @override
  ConsumerState<LabourConnectApp> createState() => _LabourConnectAppState();
}

class _LabourConnectAppState extends ConsumerState<LabourConnectApp> {
  @override
  void initState() {
    super.initState();
    // Restore any saved session on launch.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authControllerProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Labour Connect',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
