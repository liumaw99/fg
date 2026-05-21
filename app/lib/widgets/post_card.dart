import 'package:flutter/material.dart';
import '../data/models/post_model.dart';

class PostCard extends StatelessWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(30),
                  child: Text(
                    post.userId.substring(0, 2).toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        post.formattedTime,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildMediaGrid(),
            ],
            const SizedBox(height: 12),
            _buildActionBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    final media = post.mediaUrls;
    if (media.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, size: 40, color: Colors.grey),
            ),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.image, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _ActionButton(
          icon: Icons.chat_bubble_outline,
          count: post.replyCount,
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.repeat,
          count: post.repostCount,
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.favorite_outline,
          count: post.likeCount,
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.bookmark_outline,
          count: null,
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.share_outlined,
          count: null,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final int? count;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(count!),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
