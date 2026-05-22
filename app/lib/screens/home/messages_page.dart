import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../features/messaging/conversation_tile.dart';
import '../../providers/messaging_provider.dart';
import '../../ui/atoms/app_divider.dart';
import '../../ui/molecules/skeletons/list_skeletons.dart';
import '../../ui/states/empty_state.dart';
import '../../ui/states/error_state.dart';

class MessagesPage extends ConsumerStatefulWidget {
  const MessagesPage({super.key});

  @override
  ConsumerState<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends ConsumerState<MessagesPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      final n = ref.read(conversationsProvider.notifier);
      if (n.hasMore) n.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final asyncList = ref.watch(conversationsProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: asyncList.when(
        loading: () => ListView.builder(
          key: const ValueKey('conv-loading'),
          itemCount: 6,
          itemBuilder: (_, __) => const ConversationTileSkeleton(),
        ),
        error: (error, _) => ErrorState(
          key: const ValueKey('conv-error'),
          message: error.toString(),
          onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
        ),
        data: (response) {
          if (response.conversations.isEmpty) {
            return RefreshIndicator(
              key: const ValueKey('conv-empty'),
              color: theme.appTextPrimary,
              onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 80),
                  EmptyState(
                    icon: Icons.mail_outline,
                    title: AppStrings.noMessages,
                    subtitle: AppStrings.startChat,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            key: const ValueKey('conv-data'),
            color: theme.appTextPrimary,
            onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              itemCount: response.conversations.length + 1,
              separatorBuilder: (_, __) => const AppDivider(indent: 84),
              itemBuilder: (context, index) {
                if (index == response.conversations.length) {
                  final n = ref.read(conversationsProvider.notifier);
                  if (n.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  }
                  return const SizedBox(height: 60);
                }
                return ConversationTile(conversation: response.conversations[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
