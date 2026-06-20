import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/states.dart';
import 'customer_providers.dart';
import 'widgets/worker_card.dart';

class WorkersListScreen extends ConsumerStatefulWidget {
  final int? categoryId;
  final String? title;

  const WorkersListScreen({super.key, this.categoryId, this.title});

  @override
  ConsumerState<WorkersListScreen> createState() => _WorkersListScreenState();
}

class _WorkersListScreenState extends ConsumerState<WorkersListScreen> {
  final _search = TextEditingController();
  late WorkerQuery _query;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _query = WorkerQuery(categoryId: widget.categoryId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      setState(() => _query = _query.copyWith(query: value));
    });
  }

  @override
  Widget build(BuildContext context) {
    final workers = ref.watch(workerListProvider(_query));

    return Scaffold(
      appBar: AppBar(title: Text(widget.title ?? 'Find workers')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  onChanged: _onSearch,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = _query.copyWith(query: ''));
                            },
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilterChip(
                      label: const Text('Available now'),
                      selected: _query.availableOnly,
                      showCheckmark: false,
                      avatar: Icon(
                        Icons.bolt_rounded,
                        size: 16,
                        color: _query.availableOnly ? Colors.white : AppColors.textMuted,
                      ),
                      labelStyle: AppText.label.copyWith(
                        color: _query.availableOnly ? Colors.white : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (v) =>
                          setState(() => _query = _query.copyWith(availableOnly: v)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: workers.when(
              loading: () => const ListSkeleton(itemHeight: 88),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(workerListProvider(_query)),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No workers found',
                    message: 'Try turning off "Available now" or searching a different name.',
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async => ref.invalidate(workerListProvider(_query)),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => WorkerCard(
                      worker: list[i],
                      onTap: () =>
                          context.push('${Routes.workerDetail}/${list[i].userId}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
