import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../providers/search_provider.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';
import '../../ui/states/loading_state.dart';

class ExplorePage extends ConsumerStatefulWidget {
  const ExplorePage({super.key});

  @override
  ConsumerState<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends ConsumerState<ExplorePage>
    with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  late TabController _tabController;
  final _tabs = ['全部', '用户', '动态'];
  final _tabTypes = ['all', 'users', 'posts'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) _performSearch();
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    ref
        .read(searchProvider.notifier)
        .search(query, type: _tabTypes[_tabController.index]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final searchState = ref.watch(searchProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: TextField(
            controller: _controller,
            style: TextStyle(color: theme.appTextPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              hintStyle: TextStyle(color: theme.appTextTertiary, fontSize: 15),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: theme.appTextSecondary,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.cancel,
                        size: 18,
                        color: theme.appTextSecondary,
                      ),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).clear();
                        setState(() {});
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.appSurfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _performSearch(),
            textInputAction: TextInputAction.search,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.appBorder, width: 0.5),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicator: UnderlineTabIndicator(
              borderSide: BorderSide(color: theme.appTextPrimary, width: 3),
              insets: const EdgeInsets.symmetric(horizontal: 16),
            ),
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: theme.appTextPrimary,
            unselectedLabelColor: theme.appTextSecondary,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dividerColor: Colors.transparent,
            splashFactory: NoSplash.splashFactory,
            tabs: _tabs.map((t) => Tab(text: t)).toList(),
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: searchState.when(
              loading: () =>
                  const LoadingState(key: ValueKey('search-loading')),
              error: (error, _) => ErrorState(
                key: const ValueKey('search-error'),
                message: error.toString(),
                onRetry: _performSearch,
              ),
              data: (response) {
                if (_controller.text.isEmpty) {
                  return Center(
                    key: const ValueKey('search-hint'),
                    child: Text(
                      '输入关键词开始搜索',
                      style: TextStyle(
                        color: theme.appTextSecondary,
                        fontSize: 14,
                      ),
                    ),
                  );
                }
                if (response.results.isEmpty) {
                  return const EmptyState(
                    key: ValueKey('search-empty'),
                    icon: Icons.search_off,
                    title: AppStrings.noResults,
                    subtitle: '换个关键词试试',
                  );
                }
                return ListView.separated(
                  key: const ValueKey('search-data'),
                  itemCount: response.results.length,
                  separatorBuilder: (_, __) => const AppDivider(indent: 56),
                  itemBuilder: (context, index) {
                    final r = response.results[index];
                    final isUser = r.type == 'user';
                    return ListTile(
                      leading: Icon(
                        isUser ? Icons.person : Icons.article,
                        color: theme.appTextSecondary,
                      ),
                      title: Text(
                        r.title,
                        style: TextStyle(
                          color: theme.appTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: r.subtitle != null
                          ? Text(
                              r.subtitle!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            )
                          : (r.content != null
                                ? Text(
                                    r.content!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null),
                      onTap: () {
                        if (isUser) {
                          context.push('/user/${r.title}');
                        } else {
                          context.push('/post/${r.id}');
                        }
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
