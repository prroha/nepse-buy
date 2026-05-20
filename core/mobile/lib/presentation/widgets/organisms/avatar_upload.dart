import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Size presets for the avatar upload widget
enum AvatarUploadSize {
  sm(64, 20),
  md(80, 24),
  lg(100, 32),
  xl(120, 40);

  final double size;
  final double fontSize;
  const AvatarUploadSize(this.size, this.fontSize);
}

/// A widget for uploading avatar images with camera/gallery selection.
class AvatarUpload extends StatefulWidget {
  /// The current avatar URL (if any)
  final String? currentAvatarUrl;

  /// Initials to display when no avatar is set
  final String initials;

  /// Callback when a file is selected for upload
  final Future<void> Function(File file) onUpload;

  /// Callback when remove is requested
  final Future<void> Function()? onRemove;

  /// Whether an upload is in progress
  final bool isUploading;

  /// Upload progress (0-100)
  final double uploadProgress;

  /// Size of the avatar
  final AvatarUploadSize size;

  /// Whether the widget is disabled
  final bool disabled;

  const AvatarUpload({
    super.key,
    this.currentAvatarUrl,
    this.initials = 'U',
    required this.onUpload,
    this.onRemove,
    this.isUploading = false,
    this.uploadProgress = 0,
    this.size = AvatarUploadSize.lg,
    this.disabled = false,
  });

  @override
  State<AvatarUpload> createState() => _AvatarUploadState();
}

class _AvatarUploadState extends State<AvatarUpload> {
  final ImagePicker _picker = ImagePicker();
  File? _previewFile;
  String? _error;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        // Validate file size
        final fileSize = await file.length();
        if (fileSize > _maxFileSizeBytes) {
          setState(() {
            _error = 'File is too large. Maximum size is 5MB.';
          });
          return;
        }

        setState(() {
          _previewFile = file;
          _error = null;
        });

        try {
          await widget.onUpload(file);
          setState(() {
            _previewFile = null;
          });
        } catch (e) {
          setState(() {
            _error = e.toString();
            _previewFile = null;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to pick image: $e';
      });
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Text(
                'Choose Photo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.gapMd,
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.secondary,
                  ),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Select an existing photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (widget.currentAvatarUrl != null && widget.onRemove != null)
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      color: AppColors.error,
                    ),
                  ),
                  title: const Text(
                    'Remove Photo',
                    style: TextStyle(color: AppColors.error),
                  ),
                  subtitle: const Text('Delete current photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await widget.onRemove!();
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _error = e.toString();
                        });
                      }
                    }
                  },
                ),
              AppSpacing.gapSm,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with overlay
        GestureDetector(
          onTap: widget.disabled || widget.isUploading
              ? null
              : _showImageSourceDialog,
          child: Stack(
            children: [
              // Avatar circle
              Container(
                width: widget.size.size,
                height: widget.size.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary,
                  image: _getAvatarImage(),
                ),
                child: _getAvatarChild(),
              ),

              // Edit overlay
              if (!widget.isUploading && !widget.disabled)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.surface,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: AppColors.white,
                      size: widget.size == AvatarUploadSize.sm ? 12 : 16,
                    ),
                  ),
                ),

              // Loading overlay
              if (widget.isUploading)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.black.withAlpha(150),
                    ),
                    child: Center(
                      child: widget.uploadProgress > 0 &&
                              widget.uploadProgress < 100
                          ? Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: widget.size.size * 0.5,
                                  height: widget.size.size * 0.5,
                                  child: CircularProgressIndicator(
                                    value: widget.uploadProgress / 100,
                                    strokeWidth: 3,
                                    color: AppColors.white,
                                  ),
                                ),
                                Text(
                                  '${widget.uploadProgress.toInt()}%',
                                  style: const TextStyle(
                                    color: AppColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            )
                          : SizedBox(
                              width: widget.size.size * 0.4,
                              height: widget.size.size * 0.4,
                              child: const CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppColors.white,
                              ),
                            ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        AppSpacing.gapSm,

        // Hint text
        Text(
          'Tap to change photo',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),

        // Error message
        if (_error != null) ...[
          AppSpacing.gapXs,
          Text(
            _error!,
            style: const TextStyle(
              color: AppColors.error,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  DecorationImage? _getAvatarImage() {
    // Priority: preview file > current URL
    if (_previewFile != null) {
      return DecorationImage(
        image: FileImage(_previewFile!),
        fit: BoxFit.cover,
      );
    }
    if (widget.currentAvatarUrl != null) {
      return DecorationImage(
        image: NetworkImage(widget.currentAvatarUrl!),
        fit: BoxFit.cover,
        onError: (exception, stackTrace) {},
      );
    }
    return null;
  }

  Widget? _getAvatarChild() {
    if (_previewFile != null || widget.currentAvatarUrl != null) {
      return null;
    }
    return Center(
      child: Text(
        widget.initials,
        style: TextStyle(
          color: AppColors.white,
          fontSize: widget.size.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
