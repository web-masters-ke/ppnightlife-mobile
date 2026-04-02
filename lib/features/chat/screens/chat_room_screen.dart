import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const ChatRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();
  final _messages = <_Message>[];
  bool _isTyping = false;
  bool _showEmojis = false;
  String _emojiCategory = 'Reactions';
  _Message? _replyingTo;
  bool _loadingMessages = true;
  String _otherName = 'Chat';
  bool _sending = false;
  bool _recordingVoice = false;

  static const _emojis = ['❤️', '😂', '🔥', '👍', '😮', '🎉', '🎵', '💃'];
  // Extended emoji set for full picker
  static const _emojiCategories = {
    'Reactions': ['❤️', '😂', '🔥', '👍', '😮', '🎉', '🎵', '💃', '😍', '🥳', '💯', '🙌'],
    'Faces': ['😀', '😎', '🤩', '😊', '🥰', '😜', '🤭', '😏', '🤔', '😴', '🤯', '😤'],
    'Party': ['🍾', '🍻', '🥂', '🎊', '🎸', '🎤', '🎧', '🎹', '💃', '🕺', '🪩', '🎆'],
    'Nature': ['🌙', '⭐', '🌟', '✨', '🌈', '🌊', '🔮', '💫', '🌸', '🦋', '🌺', '🌴'],
  };

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      final typing = _messageController.text.isNotEmpty;
      if (typing != _isTyping) setState(() => _isTyping = typing);
    });
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    try {
      final res = await ApiService().getMessages(widget.roomId, limit: 50);
      final data = res.data['data'];
      final items = (data['items'] as List?) ?? [];
      final myId = ref.read(authProvider).user?.userId;

      setState(() {
        _messages.clear();
        for (final item in items) {
          final m = item as Map<String, dynamic>;
          final senderId = m['senderId'] as String? ?? '';
          final senderName = m['senderName'] as String? ?? 'Unknown';
          _messages.add(_Message(
            text: m['content'] as String? ?? '',
            isMine: senderId == myId,
            time: _fmtMsgTime(m['createdAt'] as String? ?? ''),
            emoji: senderName.isNotEmpty ? senderName[0] : '?',
            sender: senderId != myId ? senderName : null,
            isRead: m['read'] as bool? ?? false,
          ));
          if (senderId != myId && _otherName == 'Chat') {
            _otherName = senderName;
          }
        }
        _loadingMessages = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
    } catch (_) {
      setState(() => _loadingMessages = false);
    }
  }

  String _fmtMsgTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m ${dt.hour >= 12 ? "PM" : "AM"}';
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    HapticFeedback.lightImpact();
    setState(() {
      _messages.add(_Message(
        text: text,
        isMine: true,
        time: _timeNow(),
        emoji: '👤',
        replyTo: _replyingTo,
      ));
      _replyingTo = null;
      _showEmojis = false;
      _sending = true;
    });
    _messageController.clear();
    Future.delayed(const Duration(milliseconds: 80), () => _scrollToBottom());
    try {
      await ApiService().sendMessage(widget.roomId, content: text);
    } catch (_) {}
    setState(() => _sending = false);
  }

  void _pickAttachment() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachOption(
                  icon: HugeIcons.strokeRoundedImage01,
                  label: 'Photo',
                  color: const Color(0xFF6C5CE7),
                  onTap: () async {
                    Navigator.pop(context);
                    final xfile = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1280);
                    if (xfile == null) return;
                    final bytes = await xfile.readAsBytes();
                    final ext = xfile.name.split('.').last.toLowerCase();
                    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
                    try {
                      final res = await ApiService().uploadChatFile(bytes, xfile.name, mime);
                      final url = res.data['url'] as String? ?? '';
                      if (url.isNotEmpty) {
                        await ApiService().sendMessage(widget.roomId, attachment: {'type': 'image', 'url': url});
                        setState(() {
                          _messages.add(_Message(text: '📷 Photo', isMine: true, time: _timeNow(), emoji: '👤', isRead: false));
                        });
                        Future.delayed(const Duration(milliseconds: 80), () => _scrollToBottom());
                      }
                    } catch (_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send photo')));
                    }
                  },
                ),
                _AttachOption(
                  icon: HugeIcons.strokeRoundedVideo01,
                  label: 'Video',
                  color: const Color(0xFFE17055),
                  onTap: () async {
                    Navigator.pop(context);
                    final xfile = await ImagePicker().pickVideo(source: ImageSource.gallery);
                    if (xfile == null) return;
                    final bytes = await xfile.readAsBytes();
                    try {
                      final res = await ApiService().uploadChatFile(bytes, xfile.name, 'video/mp4');
                      final url = res.data['url'] as String? ?? '';
                      if (url.isNotEmpty) {
                        await ApiService().sendMessage(widget.roomId, attachment: {'type': 'video', 'url': url});
                        setState(() {
                          _messages.add(_Message(text: '🎬 Video', isMine: true, time: _timeNow(), emoji: '👤', isRead: false));
                        });
                        Future.delayed(const Duration(milliseconds: 80), () => _scrollToBottom());
                      }
                    } catch (_) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send video')));
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startVoiceRecord() {
    setState(() => _recordingVoice = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Voice recording — tap mic again to stop & send'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Cancel',
          onPressed: () => setState(() => _recordingVoice = false),
        ),
      ),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _recordingVoice) setState(() => _recordingVoice = false);
    });
  }

  void _addReaction(_Message msg, String emoji) {
    HapticFeedback.selectionClick();
    setState(() {
      final existing = msg.reactions[emoji] ?? 0;
      msg.reactions[emoji] = existing + 1;
    });
    Navigator.pop(context);
  }

  void _showReactionPicker(_Message msg) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.bgElevatedDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('React', style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: _emojis.map((e) => GestureDetector(
                  onTap: () => _addReaction(msg, e),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                  ),
                )).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  String _timeNow() {
    final now = DateTime.now();
    final h = now.hour % 12 == 0 ? 12 : now.hour % 12;
    final m = now.minute.toString().padLeft(2, '0');
    final suffix = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgCardDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 18),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: Center(child: Text(_otherName.isNotEmpty ? _otherName[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white))),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _otherName,
                  style: TextStyle(fontFamily: 'PlusJakartaSans', fontSize: 14, fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                ),
                const Text('Online', style: TextStyle(fontSize: 11, color: AppColors.green)),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedCall, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            onPressed: () {},
          ),
          IconButton(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 20, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            onPressed: () => _showRoomOptions(context, isDark),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _loadingMessages
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : GestureDetector(
              onTap: () {
                _focusNode.unfocus();
                setState(() => _showEmojis = false);
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                itemCount: _messages.length + 1, // +1 for typing indicator
                itemBuilder: (ctx, i) {
                  if (i == _messages.length) {
                    return _TypingIndicator(isDark: isDark);
                  }
                  final msg = _messages[i];
                  final showDate = i == 0 ||
                      _messages[i - 1].time.substring(0, _messages[i - 1].time.length - 3) !=
                          msg.time.substring(0, msg.time.length - 3);
                  return Column(
                    children: [
                      if (i == 0)
                        _DateChip(label: 'Today', isDark: isDark),
                      GestureDetector(
                        onLongPress: () => _showReactionPicker(msg),
                        child: _MessageBubble(
                          msg: msg,
                          isDark: isDark,
                          onReply: () => setState(() => _replyingTo = msg),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // Reply bar
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 32,
                    decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _replyingTo!.isMine ? 'You' : (_replyingTo!.sender ?? 'User'),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple),
                        ),
                        Text(
                          _replyingTo!.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _replyingTo = null),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ],
              ),
            ),

          // Input bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              border: Border(top: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
            ),
            padding: EdgeInsets.fromLTRB(10, 8, 10, botPad > 0 ? botPad : 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Emoji toggle
                GestureDetector(
                  onTap: () {
                    _focusNode.unfocus();
                    setState(() => _showEmojis = !_showEmojis);
                  },
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 9, right: 4),
                    child: Text(
                      _showEmojis ? '⌨️' : '😊',
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            focusNode: _focusNode,
                            maxLines: 4,
                            minLines: 1,
                            textInputAction: TextInputAction.newline,
                            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            decoration: InputDecoration(
                              hintText: 'Message...',
                              hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              isDense: true,
                            ),
                            onTapOutside: (_) {},
                          ),
                        ),
                        // Attachment
                        GestureDetector(
                          onTap: _pickAttachment,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10, bottom: 8),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedAttachment01,
                              size: 20,
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                // Send / Mic
                GestureDetector(
                  onTap: _isTyping ? _sendMessage : _startVoiceRecord,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: _isTyping ? AppColors.primaryGradient : null,
                      color: _isTyping ? null : (isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight),
                      shape: BoxShape.circle,
                      boxShadow: _isTyping
                          ? [const BoxShadow(color: Color(0x406C5CE7), blurRadius: 8, offset: Offset(0, 3))]
                          : null,
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: _isTyping ? HugeIcons.strokeRoundedSent : HugeIcons.strokeRoundedMic01,
                        size: 20,
                        color: _isTyping ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Categorized emoji picker
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: _showEmojis ? 200 : 0,
            color: isDark ? AppColors.bgCardDark : Colors.white,
            child: _showEmojis
                ? Column(
                    children: [
                      // Category tabs
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          children: _emojiCategories.keys.map((cat) {
                            final selected = cat == _emojiCategory;
                            return GestureDetector(
                              onTap: () => setState(() => _emojiCategory = cat),
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                decoration: BoxDecoration(
                                  color: selected ? const Color(0xFF6C5CE7) : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: selected ? null : Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                ),
                                child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight))),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      // Emoji grid
                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 8,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          children: (_emojiCategories[_emojiCategory] ?? []).map((e) => GestureDetector(
                            onTap: () {
                              final pos = _messageController.selection.baseOffset;
                              final text = _messageController.text;
                              final newText = pos < 0
                                  ? text + e
                                  : text.substring(0, pos) + e + text.substring(pos);
                              _messageController.value = TextEditingValue(
                                text: newText,
                                selection: TextSelection.collapsed(offset: (pos < 0 ? text.length : pos) + e.length),
                              );
                              setState(() => _isTyping = true);
                            },
                            child: Center(child: Text(e, style: const TextStyle(fontSize: 22))),
                          )).toList(),
                        ),
                      ),
                    ],
                  )
                : null,
          ),
        ],
      ),
    );
  }

  void _showRoomOptions(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgElevatedDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(color: isDark ? AppColors.borderDark : AppColors.borderLight, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            ...[
              (HugeIcons.strokeRoundedSearch01, 'Search messages'),
              (HugeIcons.strokeRoundedUserGroup, 'View members'),
              (HugeIcons.strokeRoundedNotification01, 'Mute notifications'),
              (HugeIcons.strokeRoundedLogout01, 'Leave group'),
            ].map((item) => GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    HugeIcon(icon: item.$1, size: 20, color: item.$1 == HugeIcons.strokeRoundedLogout01 ? AppColors.red : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    const SizedBox(width: 12),
                    Text(
                      item.$2,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: item.$1 == HugeIcons.strokeRoundedLogout01 ? AppColors.red : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }
}

// ── Message Bubble ─────────────────────────────────────────────────────────────
class _MessageBubble extends StatelessWidget {
  final _Message msg;
  final bool isDark;
  final VoidCallback onReply;

  const _MessageBubble({required this.msg, required this.isDark, required this.onReply});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: msg.isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isMine) ...[
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.primaryGradient),
              child: Center(child: Text(msg.emoji, style: const TextStyle(fontSize: 12))),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!msg.isMine && msg.sender != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                    child: Text(msg.sender!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.purple)),
                  ),

                // Reply preview
                if (msg.replyTo != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 3),
                    padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgElevatedDark.withOpacity(0.6) : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(10),
                      border: const Border(left: BorderSide(color: AppColors.purple, width: 3)),
                    ),
                    child: Text(
                      msg.replyTo!.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ),

                GestureDetector(
                  onDoubleTap: onReply,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: msg.isMine ? AppColors.primaryGradient : null,
                      color: msg.isMine ? null : (isDark ? AppColors.bgCardDark : AppColors.bgCardLight),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isMine ? 16 : 4),
                        bottomRight: Radius.circular(msg.isMine ? 4 : 16),
                      ),
                      boxShadow: msg.isMine
                          ? [const BoxShadow(color: Color(0x306C5CE7), blurRadius: 6, offset: Offset(0, 2))]
                          : null,
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: msg.isMine
                            ? Colors.white
                            : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                    ),
                  ),
                ),

                // Reactions
                if (msg.reactions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgElevatedDark : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: msg.reactions.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 13)),
                            if (e.value > 1) ...[
                              const SizedBox(width: 2),
                              Text('${e.value}', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                            ],
                          ],
                        ),
                      )).toList(),
                    ),
                  ),

                // Time + read receipt
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: TextStyle(fontSize: 10, color: isDark ? AppColors.textFaintDark : AppColors.textFaintLight),
                    ),
                    if (msg.isMine) ...[
                      const SizedBox(width: 3),
                      Icon(
                        msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 13,
                        color: msg.isRead ? AppColors.cyan : (isDark ? AppColors.textFaintDark : AppColors.textFaintLight),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }
}

// ── Date Chip ──────────────────────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _DateChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.bgCardDark : AppColors.bgElevatedLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
      ),
    );
  }
}

// ── Typing Indicator ──────────────────────────────────────────────────────────
class _TypingIndicator extends StatefulWidget {
  final bool isDark;
  const _TypingIndicator({required this.isDark});

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator> with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) => AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 200)));
    _animations = _controllers.map((c) => Tween<double>(begin: 0, end: 1).animate(c)).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28, height: 28,
            decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.warmGradient),
            child: const Center(child: Text('🎵', style: TextStyle(fontSize: 12))),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _animations[i],
                builder: (_, __) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6 + _animations[i].value * 4,
                  decoration: BoxDecoration(
                    color: AppColors.purple.withOpacity(0.5 + _animations[i].value * 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Model ──────────────────────────────────────────────────────────────────────
class _Message {
  final String text;
  final bool isMine;
  final String time;
  final String emoji;
  final String? sender;
  final bool isRead;
  final _Message? replyTo;
  final Map<String, int> reactions;

  _Message({
    required this.text,
    required this.isMine,
    required this.time,
    required this.emoji,
    this.sender,
    this.isRead = false,
    this.replyTo,
    Map<String, int>? reactions,
  }) : reactions = reactions ?? {};
}

// ── Attach Option ─────────────────────────────────────────────────────────────
class _AttachOption extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Center(child: HugeIcon(icon: icon, size: 28, color: color)),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

