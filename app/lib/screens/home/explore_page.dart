import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/search_provider.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

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
    if (!_tabController.indexIsChanging) {
      _performSearch();
    }
  }

  void _performSearch() {
    final query = _controller.text.trim();
    if (query.isEmpty) return;
    ref.read(searchProvider.notifier).search(
          query,
          type: _tabTypes[_tabController.index],
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final searchState = ref.watch(searchProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: AppStrings.searchHint,
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _controller.clear();
                        ref.read(searchProvider.notifier).clear();
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _performSearch(),
            textInputAction: TextInputAction.search,
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
          dividerColor: isDark ? const Color(0xFF1F1F1F) : const Color(0xFFF0F0F0),
        ),
        const AppDivider(),
        Expanded(
          child: searchState.when(
            data: (response) {
              if (_controller.text.isEmpty) {
                return const Center(
                  child: Text(
                    '输入关键词开始搜索',
                    style: TextStyle(color: Color(0xFF71717A)),
                  ),
                );
              }
              if (response.results.isEmpty) {
                return EmptyState(
                  icon: Icons.search_off,
                  title: AppStrings.noResults,
                );
              }
              return ListView.separated(
                itemCount: response.results.length,
                separatorBuilder: (_, __) => const AppDivider(indent: 56),
                itemBuilder: (context, index) {
                  final r = response.results[index];
                  final isUser = r.type == 'user';
                  return ListTile(
                    leading: Icon(
                      isUser ? Icons.person : Icons.article,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(r.title),
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
            loading: () => const LoadingState(),
            error: (error, _) => ErrorState(
              message: error.toString(),
              onRetry: _performSearch,
            ),
          ),
        ),
      ],
    );
  }
}
