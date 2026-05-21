import 'package:flutter/material.dart';
import '../data/api/interaction_api.dart';
import '../data/models/post_model.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onTap;

  const PostCard({
    super.key,
    required this.post,
    this.onTap,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late bool _isLiked;
  late int _likeCount;
  bool _isLoading = false;
  final _interactionApi = InteractionApi();

  @override
  void initState() {
    super.initState();
    _isLiked = widget.post.isLiked;
    _likeCount = widget.post.likeCount;
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    // Optimistic update
    final newIsLiked = !_isLiked;
    final newCount = newIsLiked ? _likeCount + 1 : _likeCount - 1;
    setState(() {
      _isLiked = newIsLiked;
      _likeCount = newCount;
      _isLoading = true;
    });

    try {
      if (newIsLiked) {
        await _interactionApi.like(widget.post.id);
      } else {
        await _interactionApi.unlike(widget.post.id);
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isLiked = !newIsLiked;
          _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
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
                    widget.post.userId.substring(0, 2).toUpperCase(),
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
                      const Text(
                        'User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.post.formattedTime,
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
              widget.post.content,
              style: const TextStyle(fontSize: 15, height: 1.4),
            ),
            if (widget.post.mediaUrls.isNotEmpty) ...[
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
    final media = widget.post.mediaUrls;
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
          count: widget.post.replyCount,
          onTap: () {},
        ),
        _ActionButton(
          icon: Icons.repeat,
          count: widget.post.repostCount,
          onTap: () {},
        ),
        _LikeButton(
          isLiked: _isLiked,
          count: _likeCount,
          isLoading: _isLoading,
          onTap: _toggleLike,
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

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final int count;
  final bool isLoading;
  final VoidCallback onTap;

  const _LikeButton({
    required this.isLiked,
    required this.count,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Row(
        children: [
          isLoading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isLiked ? Colors.red : Colors.grey.shade600,
                  ),
                )
              : Icon(
                  isLiked ? Icons.favorite : Icons.favorite_outline,
                  size: 18,
                  color: isLiked ? Colors.red : Colors.grey.shade600,
                ),
          if (count > 0) ...[
            const SizedBox(width: 4),
            Text(
              _formatCount(count),
              style: TextStyle(
                fontSize: 12,
                color: isLiked ? Colors.red : Colors.grey.shade600,
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
