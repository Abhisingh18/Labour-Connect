import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/ui_helpers.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/states.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../shared/models/category_model.dart';
import 'customer_providers.dart';
import 'widgets/worker_card.dart';

class CustomerHomeScreen extends ConsumerWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    final categories = ref.watch(categoriesProvider);
    final featured = ref.watch(featuredWorkersProvider);

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(categoriesProvider);
          ref.invalidate(featuredWorkersProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _Header(name: user?.name ?? 'there')),
            const SliverToBoxAdapter(child: _SearchBar()),
            const SliverToBoxAdapter(child: _PromoBanner()),
            SliverToBoxAdapter(
              child: _SectionHeader(title: 'Services', onSeeAll: null),
            ),
            categories.when(
              loading: () => const SliverToBoxAdapter(child: _CategoriesSkeleton()),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(categoriesProvider),
                ),
              ),
              data: (cats) => SliverToBoxAdapter(child: _CategoryGrid(categories: cats)),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Top rated near you',
                onSeeAll: () => context.push(Routes.categoryWorkers),
              ),
            ),
            featured.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      ShimmerBox(height: 88, radius: 20),
                      SizedBox(height: 12),
                      ShimmerBox(height: 88, radius: 20),
                    ],
                  ),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorState(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(featuredWorkersProvider),
                ),
              ),
              data: (workers) {
                if (workers.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.groups_rounded,
                        title: 'No workers online yet',
                        message: 'Check back soon — workers go online through the day.',
                      ),
                    ),
                  );
                }
                final top = workers.take(6).toList();
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  sliver: SliverList.separated(
                    itemCount: top.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => WorkerCard(
                      worker: top[i],
                      onTap: () => context.push('${Routes.workerDetail}/${top[i].userId}'),
                    ).animate().fadeIn(delay: (i * 60).ms).slideY(begin: 0.08),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String name;
  const _Header({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text('Your location', style: AppText.caption),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Hi, $name 👋', style: AppText.h1),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(Routes.categoryWorkers),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.textMuted),
                const SizedBox(width: 12),
                Text('Search electrician, plumber…', style: AppText.body),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => context.push(Routes.postJob),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppColors.heroGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koi kaam karwana hai?',
                        style: AppText.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Apna kaam post karo — hum worker dhoond denge',
                        style: AppText.label.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add_rounded,
                                color: AppColors.primary, size: 18),
                            const SizedBox(width: 4),
                            Text('Post a job',
                                style: AppText.bodyStrong
                                    .copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.post_add_rounded,
                      color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 12, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppText.h2)),
          if (onSeeAll != null)
            TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      ),
    );
  }
}

class _CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  const _CategoryGrid({required this.categories});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: categories.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, i) {
          final c = categories[i];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(
              '${Routes.categoryWorkers}?categoryId=${c.id}&title=${Uri.encodeComponent(c.name)}',
            ),
            child: Column(
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(categoryIcon(c.icon ?? c.name),
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 6),
                Text(
                  c.name,
                  style: AppText.caption.copyWith(color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ).animate().fadeIn(delay: (i * 40).ms).scale(begin: const Offset(0.9, 0.9));
        },
      ),
    );
  }
}

class _CategoriesSkeleton extends StatelessWidget {
  const _CategoriesSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisSpacing: 14,
          crossAxisSpacing: 12,
          childAspectRatio: 0.78,
        ),
        itemBuilder: (_, __) => const ShimmerBox(height: 58, radius: 18),
      ),
    );
  }
}
