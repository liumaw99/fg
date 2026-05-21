import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/api/interaction_api.dart';
import '../data/api/messaging_api.dart';
import '../data/api/search_api.dart';
import 'chat_screen.dart';
import '../providers/post_provider.dart';
import '../router/route_names.dart';
import '../widgets/post_card.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push(RouteNames.settings),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _TimelinePage(),
          _ExplorePage(),
          _NotificationsPage(),
          _MessagesPage(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications),
            label: 'Notifications',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Messages',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/create-post'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TimelinePage extends ConsumerStatefulWidget {
  const _TimelinePage();

  @override
  ConsumerState<_TimelinePage> createState() => _TimelinePageState();
}

class _TimelinePageState extends ConsumerState<_TimelinePage> {
  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(feedPostsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(feedPostsProvider.notifier).refresh(),
      child: postsAsync.when(
        data: (posts) {
          if (posts.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No posts yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Be the first to post something!'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return PostCard(
                post: post,
                onTap: () {
                  // TODO: Navigate to post detail
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(feedPostsProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExplorePage extends StatefulWidget {
  const _ExplorePage();

  @override
  State<_ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<_ExplorePage> {
  final _controller = TextEditingController();
  final _searchApi = SearchApi();
  List<dynamic> _results = [];
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _controller.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _searchApi.search(query);
      setState(() {
        _results = data['results'] as List<dynamic>? ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search users or posts...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        setState(() => _results = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _search(),
          ),
        ),
        if (_isLoading)
          const Expanded(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          Expanded(
            child: Center(child: Text('Error: $_error')),
          )
        else if (_results.isEmpty && _controller.text.isNotEmpty)
          const Expanded(
            child: Center(
              child: Text('No results found', style: TextStyle(color: Colors.grey)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (context, index) {
                final r = _results[index] as Map<String, dynamic>;
                final type = r['type'] as String? ?? '';
                return ListTile(
                  leading: Icon(
                    type == 'user' ? Icons.person : Icons.article,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(r['title'] as String? ?? ''),
                  subtitle: Text(
                    r['subtitle'] as String? ??
                        (r['content'] as String? ?? '').substring(
                            0,
                            ((r['content'] as String?)?.length ?? 0) > 60
                                ? 60
                                : (r['content'] as String?)?.length ?? 0),
                  ),
                  onTap: () {
                    // TODO: Navigate to user profile or post detail
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}

class _NotificationsPage extends StatefulWidget {
  const _NotificationsPage();

  @override
  State<_NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<_NotificationsPage> {
  List<dynamic> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final api = InteractionApi();
      final data = await api.getNotifications();
      setState(() {
        _notifications = data['notifications'] as List<dynamic>? ?? [];
        _unreadCount = data['unread_count'] as int? ?? 0;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final api = InteractionApi();
      await api.markAllNotificationsAsRead();
      _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_notifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (_unreadCount > 0)
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextButton(
              onPressed: _markAllAsRead,
              child: Text('Mark all as read ($_unreadCount)'),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final n = _notifications[index] as Map<String, dynamic>;
              final isRead = n['is_read'] as bool? ?? false;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRead
                      ? Colors.grey.shade200
                      : Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Icon(
                    _getIcon(n['type'] as String? ?? ''),
                    color: isRead ? Colors.grey : Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  n['content'] as String? ?? '',
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(n['created_at']?.toString() ?? ''),
                tileColor: isRead ? null : Colors.blue.withAlpha(10),
              );
            },
          ),
        ),
      ],
    );
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'reply':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }
}

class _MessagesPage extends StatefulWidget {
  const _MessagesPage();

  @override
  State<_MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<_MessagesPage> {
  final _api = MessagingApi();
  List<dynamic> _conversations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    try {
      final data = await _api.getConversations();
      setState(() {
        _conversations = data['conversations'] as List<dynamic>? ?? [];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadConversations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_conversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _conversations.length,
        itemBuilder: (context, index) {
          final c = _conversations[index] as Map<String, dynamic>;
          final lastMsg = c['last_message'] as Map<String, dynamic>?;
          final unread = c['unread_count'] as int? ?? 0;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
              child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
            ),
            title: Text(
              'User ${c['participant_id']?.toString().substring(0, 8) ?? ''}',
              style: TextStyle(
                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              lastMsg?['content']?.toString() ?? 'No messages',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: unread > 0 ? Colors.black87 : Colors.grey,
                fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
            trailing: unread > 0
                ? Badge(
                    label: Text('$unread'),
                    child: const Icon(Icons.chevron_right),
                  )
                : const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ChatScreen(
                    conversationId: c['id'] as String,
                    participantId: c['participant_id'] as String?,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
