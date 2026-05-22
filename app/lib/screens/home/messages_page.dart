import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_strings.dart';
import '../../providers/messaging_provider.dart';
import '../../widgets/app_divider.dart';
import '../../widgets/conversation_tile.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

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
        _scrollController.position.maxScrollExtent - 200) {
      final notifier = ref.read(conversationsProvider.notifier);
      if (notifier.hasMore) {
        notifier.loadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(conversationsProvider.notifier).refresh(),
      child: conversationsAsync.when(
        data: (response) {
          if (response.conversations.isEmpty) {
            return EmptyState(
              icon: Icons.mail_outline,
              title: AppStrings.noMessages,
              subtitle: AppStrings.startChat,
            );
          }

          return ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: response.conversations.length + 1,
            separatorBuilder: (_, __) => const AppDivider(indent: 72),
            itemBuilder: (context, index) {
              if (index == response.conversations.length) {
                final notifier = ref.read(conversationsProvider.notifier);
                if (notifier.hasMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }

              final c = response.conversations[index];
              return ConversationTile(
                conversation: c,
                onTap: () => context.push(
                  '/chat/${c.id}',
                  extra: c.participantId,
                ),
              );
            },
          );
        },
        loading: () => const LoadingState(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.read(conversationsProvider.notifier).refresh(),
        ),
      ),
    );
  }
}
