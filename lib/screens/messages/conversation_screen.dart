import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/messages_provider.dart';
import '../../models/conversation_model.dart';
import '../../models/message_model.dart';
import '../../utils/theme.dart';

class ConversationScreen extends StatefulWidget {
  final ConversationModel conversation;

  const ConversationScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  
  Future<void> _loadMessages() async {
    setState(() {
      _isLoadingMessages = true;
    });

    final auth = context.read<AuthProvider>();
    final currentUserId = auth.user?.id ?? 0;
    
    if (currentUserId == 0) {
      setState(() {
        _isLoadingMessages = false;
      });
      _showError('Usuário não autenticado');
      return;
    }
    
    await context.read<MessagesProvider>().fetchMessages(
      adId: widget.conversation.adId,
      otherUserId: widget.conversation.otherUserId,
      currentUserId: currentUserId,
    );

    setState(() {
      _isLoadingMessages = false;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    _messageController.clear();
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthProvider>();
    final currentUserId = auth.user?.id ?? 0;
    
    if (currentUserId == 0) {
      _showError('Usuário não autenticado');
      return;
    }
    
    await context.read<MessagesProvider>().sendMessage(
      adId: widget.conversation.adId,
      receiverId: widget.conversation.otherUserId,
      currentUserId: currentUserId,
      message: message,
    );

    // Refresh messages to get the newly sent one
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final messagesProvider = context.watch<MessagesProvider>();
    final messages = messagesProvider.messagesFor(
      widget.conversation.adId,
      widget.conversation.otherUserId,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.otherUserName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (widget.conversation.adTitle.isNotEmpty)
              Text(
                widget.conversation.adTitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
        foregroundColor: AppColors.textPrimary,
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: _isLoadingMessages && messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.message_outlined,
                              size: 64,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma mensagem',
                              style: AppTextStyles.heading3,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Seja o primeiro a enviar uma mensagem!',
                              style: AppTextStyles.bodySmall,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          final isMe = message.senderId == auth.user?.id;
                          
                          return _MessageBubble(
                            message: message,
                            isMe: isMe,
                          );
                        },
                      ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Digite uma mensagem...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: messagesProvider.isSending ? null : _sendMessage,
                  icon: messagesProvider.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary,
              child: Text(
                message.senderName[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.message,
                    style: TextStyle(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt.toString()),
                    style: TextStyle(
                      color: isMe
                          ? Colors.white.withOpacity(0.8)
                          : AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Icon(
                Icons.person,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(String dateTime) {
    final date = DateTime.tryParse(dateTime);
    if (date == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Agora';
    }
  }
}
