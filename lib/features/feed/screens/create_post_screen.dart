import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/services/api_service.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  /// 'text', 'photo', or 'video'
  final String postType;

  const CreatePostScreen({super.key, this.postType = 'text'});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _textCtrl = TextEditingController();
  final _focusNode = FocusNode();

  // Picked image data: list of (bytes, name, url) tuples stored as maps
  final List<_MediaItem> _images = [];
  _MediaItem? _video;

  int _uploadingCount = 0;
  bool get _uploading => _uploadingCount > 0;
  bool _posting = false;
  double _uploadProgress = 0;

  static const int _maxImages = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.postType == 'photo') {
        _pickImages();
      } else if (widget.postType == 'video') {
        _pickVideo();
      }
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  bool get _hasContent =>
      _textCtrl.text.trim().isNotEmpty ||
      _images.isNotEmpty ||
      _video != null;

  bool get _allUploaded {
    for (final img in _images) {
      if (img.url == null) return false;
    }
    if (_video != null && _video!.url == null) return false;
    return true;
  }

  bool get _canPost => _hasContent && _allUploaded && !_uploading && !_posting;

  String get _effectivePostType {
    if (_video != null) return 'video';
    if (_images.isNotEmpty) return 'photo';
    return 'text';
  }

  // ── Media picking ─────────────────────────────────────────────────────────────

  Future<void> _pickImages() async {
    if (_images.length >= _maxImages) return;
    try {
      final remaining = _maxImages - _images.length;
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 85,
        maxWidth: 1280,
        limit: remaining,
      );
      if (picked.isEmpty) return;

      final newItems = <_MediaItem>[];
      for (final xfile in picked) {
        final bytes = await xfile.readAsBytes();
        final item = _MediaItem(bytes: bytes, name: xfile.name);
        newItems.add(item);
      }
      setState(() => _images.addAll(newItems));
      // Upload all picked images in parallel
      await Future.wait(newItems.map(_uploadImage));
    } catch (_) {
      _showError('Failed to pick images');
    }
  }

  Future<void> _uploadImage(_MediaItem item) async {
    setState(() {
      _uploadingCount++;
      _uploadProgress = 0;
    });
    try {
      final ext = item.name.split('.').last.toLowerCase();
      final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
      final res = await ApiService().uploadPostMedia(item.bytes, item.name, mime);
      final url = res.data['url'] as String? ?? '';
      if (mounted) {
        setState(() {
          item.url = url;
          _uploadingCount--;
          _uploadProgress = 1;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _images.remove(item);
          _uploadingCount--;
        });
        _showError('Failed to upload image');
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final xfile = await ImagePicker().pickVideo(source: ImageSource.gallery);
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      final item = _MediaItem(bytes: bytes, name: xfile.name);
      setState(() => _video = item);
      await _uploadVideo(item);
    } catch (_) {
      _showError('Failed to pick video');
    }
  }

  Future<void> _uploadVideo(_MediaItem item) async {
    setState(() {
      _uploadingCount++;
      _uploadProgress = 0;
    });
    try {
      final res = await ApiService().uploadPostMedia(item.bytes, item.name, 'video/mp4');
      final url = res.data['url'] as String? ?? '';
      if (mounted) {
        setState(() {
          item.url = url;
          _uploadingCount--;
          _uploadProgress = 1;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _video = null;
          _uploadingCount--;
        });
        _showError('Failed to upload video');
      }
    }
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _removeVideo() {
    setState(() => _video = null);
  }

  // ── Post submission ───────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (!_canPost) return;
    setState(() => _posting = true);

    try {
      final List<String> mediaUrls = [
        ..._images.map((e) => e.url ?? '').where((u) => u.isNotEmpty),
        if (_video?.url != null && _video!.url!.isNotEmpty) _video!.url!,
      ];

      final res = await ApiService().createPost({
        'content': _textCtrl.text.trim(),
        'type': _effectivePostType,
        if (mediaUrls.isNotEmpty) 'media': mediaUrls,
      });

      final data = res.data['data'] ?? res.data['post'] ?? res.data;
      if (mounted) {
        Navigator.of(context).pop(data);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _posting = false);
        _showError('Failed to create post. Please try again.');
      }
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppColors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;

    final bgColor = isDark ? AppColors.bgDark : AppColors.bgLight;
    final cardColor = isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedCancel01,
            color: textPrimary,
            size: 24,
          ),
        ),
        title: Text(
          _titleForType(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _PostButton(
              enabled: _canPost,
              loading: _posting,
              onTap: _submit,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Author row
                  _AuthorRow(user: user, isDark: isDark),
                  const SizedBox(height: 14),

                  // Text input
                  TextField(
                    controller: _textCtrl,
                    focusNode: _focusNode,
                    maxLines: null,
                    minLines: widget.postType == 'text' ? 6 : 3,
                    style: TextStyle(
                      fontSize: 16,
                      color: textPrimary,
                      height: 1.5,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'What\'s the vibe tonight?',
                      hintStyle: TextStyle(color: textMuted, fontSize: 16),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Upload progress
                  if (_uploading) ...[
                    _UploadProgressBar(isDark: isDark),
                    const SizedBox(height: 16),
                  ],

                  // Image previews
                  if (_images.isNotEmpty) ...[
                    _ImagePreviewGrid(
                      images: _images,
                      isDark: isDark,
                      onRemove: _removeImage,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Video preview
                  if (_video != null) ...[
                    _VideoPreviewCard(
                      video: _video!,
                      isDark: isDark,
                      onRemove: _removeVideo,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action bar
          _BottomActionBar(
            isDark: isDark,
            borderColor: borderColor,
            cardColor: cardColor,
            textMuted: textMuted,
            canAddMoreImages: _images.length < _maxImages && _video == null,
            canAddVideo: _images.isEmpty && _video == null,
            uploading: _uploading,
            onPickImage: _pickImages,
            onPickVideo: _pickVideo,
            onCheckin: _showCheckinPlaceholder,
          ),
        ],
      ),
    );
  }

  String _titleForType() {
    switch (widget.postType) {
      case 'photo':
        return 'New Photo Post';
      case 'video':
        return 'New Video Post';
      default:
        return 'Create Post';
    }
  }

  void _showCheckinPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Check-in coming soon!'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _PostButton extends StatelessWidget {
  final bool enabled;
  final bool loading;
  final VoidCallback onTap;

  const _PostButton({
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: enabled ? AppColors.primaryGradient : null,
          color: enabled ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: enabled
              ? null
              : Border.all(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppColors.borderDark
                      : AppColors.borderLight,
                ),
        ),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Post',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: enabled
                        ? Colors.white
                        : (Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textMutedDark
                            : AppColors.textMutedLight),
                  ),
                ),
        ),
      ),
    );
  }
}

class _AuthorRow extends StatelessWidget {
  final dynamic user;
  final bool isDark;

  const _AuthorRow({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final name = user?.name as String? ?? 'You';
    final photo = user?.profilePhoto as String?;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Row(
      children: [
        // Avatar
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: photo == null ? AppColors.primaryGradient : null,
            color: photo != null
                ? (isDark ? AppColors.bgCardDark : AppColors.bgCardLight)
                : null,
          ),
          child: ClipOval(
            child: photo != null
                ? Image.network(
                    photo,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(name),
                  )
                : _initials(name),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3)),
              ),
              child: Text(
                'Public',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.purple,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _initials(String name) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
        : (name.isNotEmpty ? name[0].toUpperCase() : '?');
    return Container(
      color: Colors.transparent,
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class _UploadProgressBar extends StatelessWidget {
  final bool isDark;
  const _UploadProgressBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Uploading media...',
          style: TextStyle(fontSize: 12, color: textMuted),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            backgroundColor:
                isDark ? AppColors.borderDark : AppColors.borderLight,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purple),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _ImagePreviewGrid extends StatelessWidget {
  final List<_MediaItem> images;
  final bool isDark;
  final void Function(int index) onRemove;

  const _ImagePreviewGrid({
    required this.images,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final count = images.length;
    if (count == 1) {
      return _buildSingleImage(0);
    }
    if (count == 2) {
      return Row(
        children: [
          Expanded(child: _buildSingleImage(0)),
          const SizedBox(width: 4),
          Expanded(child: _buildSingleImage(1)),
        ],
      );
    }
    if (count == 3) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1,
              child: _buildImageTile(0),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildImageTile(1, height: null),
                const SizedBox(height: 4),
                _buildImageTile(2, height: null),
              ],
            ),
          ),
        ],
      );
    }
    // 4 images — 2x2 grid
    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(count, (i) => _buildImageTile(i)),
    );
  }

  Widget _buildSingleImage(int index) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: _buildImageTile(index),
    );
  }

  Widget _buildImageTile(int index, {double? height}) {
    final item = images[index];
    final isUploading = item.url == null;

    Widget imageWidget;
    if (item.url != null) {
      imageWidget = Image.network(
        item.url!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => Image.memory(
          item.bytes,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    } else {
      imageWidget = Image.memory(
        item.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          imageWidget,

          // Upload overlay
          if (isUploading)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // Remove button
          Positioned(
            top: 6,
            right: 6,
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoPreviewCard extends StatelessWidget {
  final _MediaItem video;
  final bool isDark;
  final VoidCallback onRemove;

  const _VideoPreviewCard({
    required this.video,
    required this.isDark,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor =
        isDark ? AppColors.bgCardDark : AppColors.bgCardLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final isUploading = video.url == null;

    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Stack(
        children: [
          // Video placeholder (thumbnail not available without video_thumbnail package)
          Center(
            child: isUploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Uploading video...',
                        style: TextStyle(fontSize: 13, color: textMuted),
                      ),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.name,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
          ),

          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppColors.red.withValues(alpha: 0.4)),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.red,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  final bool isDark;
  final Color borderColor;
  final Color cardColor;
  final Color textMuted;
  final bool canAddMoreImages;
  final bool canAddVideo;
  final bool uploading;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onCheckin;

  const _BottomActionBar({
    required this.isDark,
    required this.borderColor,
    required this.cardColor,
    required this.textMuted,
    required this.canAddMoreImages,
    required this.canAddVideo,
    required this.uploading,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onCheckin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              _ActionIconButton(
                icon: HugeIcons.strokeRoundedImage01,
                label: 'Photo',
                color: AppColors.purple,
                enabled: canAddMoreImages && !uploading,
                onTap: onPickImage,
                textMuted: textMuted,
              ),
              _ActionIconButton(
                icon: HugeIcons.strokeRoundedVideo01,
                label: 'Video',
                color: AppColors.pink,
                enabled: canAddVideo && !uploading,
                onTap: onPickVideo,
                textMuted: textMuted,
              ),
              _ActionIconButton(
                icon: HugeIcons.strokeRoundedLocation01,
                label: 'Check-in',
                color: AppColors.orange,
                enabled: !uploading,
                onTap: onCheckin,
                textMuted: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  final List<List<dynamic>> icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  final Color textMuted;

  const _ActionIconButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ─────────────────────────────────────────────────────────────────

class _MediaItem {
  final Uint8List bytes;
  final String name;
  String? url;

  _MediaItem({required this.bytes, required this.name, this.url});
}
