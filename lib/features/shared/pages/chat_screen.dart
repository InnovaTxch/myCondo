import 'package:flutter/material.dart';
import 'package:mycondo/services/shared/chat_services.dart';
import 'package:mycondo/utils/app_snackbar.dart';
import 'package:mycondo/features/shared/widgets/app_states.dart';

class ChatScreen extends StatefulWidget {
  final String name;
  final int conversationId;
  final bool showBackButton;

  const ChatScreen({
    super.key,
    required this.name,
    required this.conversationId,
    this.showBackButton = true,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final _service = MessagingService();
  String? _myProfileId;
  DateTime? _lastReadAtWhenOpened;
  bool _didCaptureReadMarker = false;
  bool _isTyping = false;

  // Blue color palette
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color deepBlue = Color(0xFF1D4ED8);
  static const Color bgColor = Color(0xFFF0F4FF);
  static const Color bubbleOther = Color(0xFFFFFFFF);

  @override
  void initState() {
    super.initState();
    _loadProfileId();
    _loadReadMarkerThenMarkRead();
    _controller.addListener(() {
      setState(() => _isTyping = _controller.text.trim().isNotEmpty);
    });
  }

  Future<void> _loadReadMarkerThenMarkRead() async {
    if (_didCaptureReadMarker) return;
    _didCaptureReadMarker = true;

    try {
      final lastReadAt =
      await _service.currentUserLastReadAt(widget.conversationId);

      if (mounted) {
        setState(() => _lastReadAtWhenOpened = lastReadAt);
      }

      await _service.markConversationRead(widget.conversationId);
    } catch (e) {
      debugPrint('Failed to mark conversation read: $e');
    }
  }

  Future<void> _loadProfileId() async {
    final profileId = await _service.currentProfileId;
    if (!mounted) return;
    setState(() => _myProfileId = profileId);
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    setState(() => _isTyping = false);

    try {
      await _service.sendMessage(
        conversationId: widget.conversationId,
        content: text,
      );
    } catch (e) {
      if (!mounted) return;
      context.showAppSnackBar(SnackBar(content: Text("Send failed: $e")));
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '';
    }
  }

  DateTime? _messageCreatedAt(Map<String, dynamic> message) {
    final value = message['created_at'];
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  bool _isUnreadIncomingMessage(Map<String, dynamic> message, String? myId) {
    final lastReadAt = _lastReadAtWhenOpened;
    final createdAt = _messageCreatedAt(message);

    if (lastReadAt == null || createdAt == null || myId == null) {
      return false;
    }

    return message['sender_id'] != myId && createdAt.isAfter(lastReadAt);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final myId = _myProfileId;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _service.messagesStream(widget.conversationId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const AppErrorState(
                    message: 'Connection error. Check Realtime settings.',
                  );
                }
                if (!snapshot.hasData) {
                  return const AppLoadingState(
                    color: primaryBlue,
                    strokeWidth: 2,
                  );
                }

                final messages = snapshot.data!;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    _loadReadMarkerThenMarkRead();
                  }
                });

                if (messages.isEmpty) {
                  return const AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    message: 'Say hello!',
                    card: false,
                  );
                }

                return ListView.builder(
                  reverse: true,
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['sender_id'] == myId;
                    final timeStr = _formatTime(msg['created_at']);

                    final isUnreadIncoming = _isUnreadIncomingMessage(msg, myId);
                    final olderMessage = index + 1 < messages.length ? messages[index + 1] : null;
                    final olderMessageIsUnread = olderMessage != null &&
                        _isUnreadIncomingMessage(olderMessage, myId);

                    final showUnreadDivider = isUnreadIncoming && !olderMessageIsUnread;

                    // Check if we should show date separator
                    final bool showTime = index == messages.length - 1 ||
                        (index + 1 < messages.length &&
                            msg['sender_id'] != messages[index + 1]['sender_id']);

                    return Column(
                      children: [
                        if (showUnreadDivider) _buildUnreadDivider(),
                        _buildMessageBubble(msg, isMe, timeStr, showTime),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: const Color(0xFFE8EEFF),
        ),
      ),
      title: Padding(
        padding: EdgeInsets.only(
            left: widget.showBackButton ? 0 : 16, right: 16),
        child: Row(
          children: [
            if (widget.showBackButton)
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded,
                    color: Color(0xFF1E293B), size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            // Avatar
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [primaryBlue, deepBlue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _getInitials(widget.name),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.name,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Action buttons
            IconButton(
              icon: Icon(Icons.call_outlined,
                  color: primaryBlue, size: 22),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.videocam_outlined,
                  color: primaryBlue, size: 22),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
      Map<String, dynamic> msg, bool isMe, String timeStr, bool showTime) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe) ...[
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8, bottom: 2),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [primaryBlue, deepBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(widget.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? primaryBlue : bubbleOther,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isMe
                            ? primaryBlue.withOpacity(0.25)
                            : Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['content'] ?? '',
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF1E293B),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 4),
            ],
          ),
          if (showTime && timeStr.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                  top: 4,
                  left: isMe ? 0 : 40,
                  bottom: 8),
              child: Text(
                timeStr,
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Input field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F4FF),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isTyping
                      ? primaryBlue.withOpacity(0.4)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined,
                        color: Colors.grey[400], size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                            color: Color(0xFFADB5C7), fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.attach_file_rounded,
                        color: Colors.grey[400], size: 20),
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send button
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _isTyping
                    ? [lightBlue, deepBlue]
                    : [Colors.grey.shade300, Colors.grey.shade300],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: _isTyping
                  ? [
                      BoxShadow(
                        color: primaryBlue.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(23),
                onTap: _isTyping ? _sendMessage : null,
                child: Center(
                  child: Icon(
                    Icons.send_rounded,
                    color: _isTyping ? Colors.white : Colors.grey[400],
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnreadDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: const [
          Expanded(child: Divider(color: Color(0xFFBFDBFE))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              'Unread messages',
              style: TextStyle(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: Color(0xFFBFDBFE))),
        ],
      ),
    );
  }
}
