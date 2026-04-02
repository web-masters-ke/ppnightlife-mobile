import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../../../core/providers/auth_provider.dart';

class PostDetailScreen extends ConsumerStatefulWidget {
  final String postId;
  const PostDetailScreen({super.key, required this.postId});

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _post;
  List<Map<String, dynamic>> _comments = [];
  bool _loadingPost = true;
  bool _loadingComments = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadComments();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadPost() async {
    try {
      final res = await ApiService().getPost(widget.postId);
      if (mounted) setState(() { _post = res.data['data']; _loadingPost = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingPost = false);
    }
  }

  Future<void> _loadComments() async {
    try {
      final res = await ApiService().getComments(widget.postId);
      final items = ((res.data['data'] as List?) ?? []).cast<Map<String, dynamic>>();
      if (mounted) setState(() { _comments = items; _loadingComments = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingComments = false);
    }
  }

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty || _submitting) return;
    HapticFeedback.lightImpact();
    setState(() => _submitting = true);
    try {
      await ApiService().addComment(widget.postId, text);
      _commentCtrl.clear();
      _focusNode.unfocus();
      await _loadComments();
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to post comment'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _fmtTime(String? iso) {
    if (iso == null) return '';
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso).toLocal());
      if (diff.inMinutes < 1) return 'just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botPad = MediaQuery.of(context).padding.bottom;
    final me = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.bgDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: isDark ? 0 : 1,
        title: Text(
          'Post',
          style: TextStyle(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        actions: [
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShare01,
              size: 20,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loadingPost
                ? const Center(child: CircularProgressIndicator(color: AppColors.purple))
                : CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      // Post card inline
                      if (_post != null)
                        SliverToBoxAdapter(child: _PostCard(post: _post!, isDark: isDark)),

                      // Comments header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Row(
                            children: [
                              Text(
                                'Comments',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_comments.length}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Comments list
                      if (_loadingComments)
                        const SliverToBoxAdapter(child: Center(child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(color: AppColors.purple),
                        )))
                      else if (_comments.isEmpty)
                        SliverToBoxAdapter(child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                          )),
                        ))
                      else
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _CommentTile(comment: _comments[i], isDark: isDark, fmtTime: _fmtTime),
                            childCount: _comments.length,
                          ),
                        ),

                      const SliverToBoxAdapter(child: SizedBox(height: 16)),
                    ],
                  ),
          ),

          // Comment input bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.bgCardDark : Colors.white,
              border: Border(top: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 0.5,
              )),
            ),
            padding: EdgeInsets.fromLTRB(12, 8, 12, botPad > 0 ? botPad : 12),
            child: Row(
              children: [
                Container(
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: me?.profilePhoto != null
                      ? ClipOval(child: Image.network(me!.profilePhoto!, width: 34, height: 34, fit: BoxFit.cover))
                      : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18, color: Colors.white)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.bgElevatedDark : AppColors.bgElevatedLight,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentCtrl,
                            focusNode: _focusNode,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _submitComment(),
                            style: TextStyle(fontSize: 14, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: TextStyle(fontSize: 14, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            ),
                            onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          ),
                        ),
                        GestureDetector(
                          onTap: _submitComment,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _submitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                                : const HugeIcon(icon: HugeIcons.strokeRoundedSent, size: 20, color: AppColors.purple),
                          ),
                        ),
                      ],
                    ),
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

// ── Inline post card ──────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final bool isDark;
  const _PostCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final author = post['author'] as Map<String, dynamic>? ?? {};
    final name = author['name'] as String? ?? 'User';
    final photo = author['profilePhoto'] as String?;
    final content = post['content'] as String? ?? '';
    final venue = (post['venue'] as Map<String, dynamic>?)?['name'] as String? ?? '';
    final likes = (post['reactionCount'] as num?)?.toInt() ?? 0;
    final comments = (post['commentCount'] as num?)?.toInt() ?? 0;
    final mediaUrls = (post['mediaUrls'] as List?)?.cast<String>() ?? [];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgDark : AppColors.bgLight,
        border: Border(bottom: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
                  child: photo != null
                      ? ClipOval(child: Image.network(photo, width: 40, height: 40, fit: BoxFit.cover))
                      : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 20, color: Colors.white)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      if (venue.isNotEmpty)
                        Text('@ $venue', style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (content.isNotEmpty)
              Text(content, style: TextStyle(fontSize: 15, height: 1.5, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
            if (mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(mediaUrls.first, width: double.infinity, height: 220, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 220, color: AppColors.bgElevatedDark)),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                const SizedBox(width: 4),
                Text('$likes', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                const SizedBox(width: 14),
                HugeIcon(icon: HugeIcons.strokeRoundedMessage01, size: 16, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                const SizedBox(width: 4),
                Text('$comments', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Comment tile ──────────────────────────────────────────────────────────────
class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final bool isDark;
  final String Function(String?) fmtTime;
  const _CommentTile({required this.comment, required this.isDark, required this.fmtTime});

  @override
  Widget build(BuildContext context) {
    final author = comment['author'] as Map<String, dynamic>? ?? {};
    final name = author['name'] as String? ?? 'User';
    final photo = author['profilePhoto'] as String?;
    final content = comment['content'] as String? ?? '';
    final time = fmtTime(comment['createdAt'] as String?);
    final likes = (comment['likeCount'] as num?)?.toInt() ?? 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient, shape: BoxShape.circle),
            child: photo != null
                ? ClipOval(child: Image.network(photo, width: 34, height: 34, fit: BoxFit.cover))
                : const Center(child: HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 18, color: Colors.white)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.bgCardDark : AppColors.bgCardLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                      const SizedBox(height: 2),
                      Text(content, style: TextStyle(fontSize: 14, height: 1.4, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(time, style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    if (likes > 0) ...[
                      const SizedBox(width: 12),
                      HugeIcon(icon: HugeIcons.strokeRoundedFavourite, size: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                      const SizedBox(width: 3),
                      Text('$likes', style: TextStyle(fontSize: 11, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
