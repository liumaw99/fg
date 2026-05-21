import 'package:flutter/material.dart';
import '../data/api/messaging_api.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? participantId;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.participantId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _api = MessagingApi();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  String? _error;
  int _msgCounter = 0;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final data = await _api.getMessages(widget.conversationId);
      setState(() {
        _messages = (data['messages'] as List<dynamic>?)?.reversed.toList() ?? [];
        _isLoading = false;
        _error = null;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    final clientMsgId = 'client-${DateTime.now().millisecondsSinceEpoch}-${_msgCounter++}';
    final tempMsg = {
      'id': 'temp',
      'content': content,
      'sender_id': 'me',
      'status': 'sending',
      'created_at': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMsg);
      _controller.clear();
    });
    _scrollToBottom();

    try {
      await _api.sendMessage(
        conversationId: widget.conversationId,
        content: content,
        clientMessageId: clientMsgId,
      );
      _loadMessages();
    } catch (e) {
      setState(() {
        tempMsg['status'] = 'failed';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with User ${widget.participantId?.substring(0, 8) ?? ''}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            ElevatedButton(
                              onPressed: _loadMessages,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index] as Map<String, dynamic>;
                          final isMe = msg['sender_id'] == 'me' ||
                              msg['sender_id']?.toString().startsWith('aa94') == true;
                          return _MessageBubble(
                            content: msg['content']?.toString() ?? '',
                            isMe: isMe,
                            status: msg['status']?.toString() ?? 'sent',
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMe;
  final String status;

  const _MessageBubble({
    required this.content,
    required this.isMe,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              content,
              style: TextStyle(
                color: isMe ? Colors.white : Colors.black87,
              ),
            ),
            if (isMe)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  status == 'failed'
                      ? Icons.error_outline
                      : status == 'sending'
                          ? Icons.access_time
                          : Icons.done,
                  size: 12,
                  color: status == 'failed' ? Colors.red : Colors.white70,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
