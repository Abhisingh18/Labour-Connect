import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'worker_dashboard_screen.dart';
import 'worker_earnings_screen.dart';
import 'worker_profile_screen.dart';
import 'worker_requests_screen.dart';

/// Bottom-nav shell hosting the worker's main tabs.
class WorkerShell extends StatefulWidget {
  final int initialIndex;
  const WorkerShell({super.key, this.initialIndex = 0});

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  late int _index = widget.initialIndex;

  static const _pages = [
    WorkerDashboardScreen(),
    WorkerRequestsScreen(),
    WorkerEarningsScreen(),
    WorkerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: _index,
            onTap: (i) => setState(() => _index = i),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment_outlined),
                activeIcon: Icon(Icons.assignment_rounded),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Earnings',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                activeIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
