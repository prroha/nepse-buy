import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../atoms/app_badge.dart';

/// Size presets for the user avatar.
enum UserAvatarSize {
  /// Extra small avatar (24px)
  xs,

  /// Small avatar (32px)
  sm,

  /// Medium avatar (40px)
  md,

  /// Large avatar (56px)
  lg,

  /// Extra large avatar (80px)
  xl,
}

/// A user avatar with initials fallback and optional badge.
///
/// This is an organism-level widget that displays a user's avatar image
/// or falls back to their initials.
///
/// Example:
/// ```dart
/// UserAvatar(
///   imageUrl: 'https://example.com/avatar.jpg',
///   name: 'John Doe',
///   size: UserAvatarSize.lg,
///   showBadge: true,
/// )
/// ```
class UserAvatar extends StatelessWidget {
  /// The URL of the avatar image.
  final String? imageUrl;

  /// The user's name (used for initials fallback).
  final String? name;

  /// The size of the avatar.
  final UserAvatarSize size;

  /// Whether to show a notification badge.
  final bool showBadge;

  /// Badge count to display.
  final int? badgeCount;

  /// Badge variant.
  final AppBadgeVariant badgeVariant;

  /// Custom background color for initials fallback.
  final Color? backgroundColor;

  /// Custom text color for initials.
  final Color? textColor;

  /// Callback when the avatar is tapped.
  final VoidCallback? onTap;

  /// Whether to show an online indicator.
  final bool showOnlineIndicator;

  /// Whether the user is online.
  final bool isOnline;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = UserAvatarSize.md,
    this.showBadge = false,
    this.badgeCount,
    this.badgeVariant = AppBadgeVariant.error,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  });

  /// Creates a small avatar.
  const UserAvatar.small({
    super.key,
    this.imageUrl,
    this.name,
    this.showBadge = false,
    this.badgeCount,
    this.badgeVariant = AppBadgeVariant.error,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : size = UserAvatarSize.sm;

  /// Creates a large avatar.
  const UserAvatar.large({
    super.key,
    this.imageUrl,
    this.name,
    this.showBadge = false,
    this.badgeCount,
    this.badgeVariant = AppBadgeVariant.error,
    this.backgroundColor,
    this.textColor,
    this.onTap,
    this.showOnlineIndicator = false,
    this.isOnline = false,
  }) : size = UserAvatarSize.lg;

  double get _size {
    switch (size) {
      case UserAvatarSize.xs:
        return 24;
      case UserAvatarSize.sm:
        return 32;
      case UserAvatarSize.md:
        return 40;
      case UserAvatarSize.lg:
        return 56;
      case UserAvatarSize.xl:
        return 80;
    }
  }

  double get _fontSize {
    switch (size) {
      case UserAvatarSize.xs:
        return 10;
      case UserAvatarSize.sm:
        return 12;
      case UserAvatarSize.md:
        return 14;
      case UserAvatarSize.lg:
        return 20;
      case UserAvatarSize.xl:
        return 28;
    }
  }

  double get _indicatorSize {
    switch (size) {
      case UserAvatarSize.xs:
        return 6;
      case UserAvatarSize.sm:
        return 8;
      case UserAvatarSize.md:
        return 10;
      case UserAvatarSize.lg:
        return 12;
      case UserAvatarSize.xl:
        return 16;
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
    }
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    Widget avatar = Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.primary,
        shape: BoxShape.circle,
        image: imageUrl != null
            ? DecorationImage(
                image: NetworkImage(imageUrl!),
                fit: BoxFit.cover,
                onError: (exception, stackTrace) {},
              )
            : null,
      ),
      child: imageUrl == null
          ? Center(
              child: Text(
                name != null ? _getInitials(name!) : '?',
                style: TextStyle(
                  color: textColor ?? AppColors.white,
                  fontSize: _fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );

    // Wrap with badge or online indicator
    if (showBadge || showOnlineIndicator) {
      avatar = Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          if (showBadge)
            Positioned(
              right: -2,
              top: -2,
              child: badgeCount != null
                  ? AppBadge.count(badgeCount!, variant: badgeVariant)
                  : AppBadge.dot(variant: badgeVariant),
            ),
          if (showOnlineIndicator)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.surface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      );
    }

    // Wrap with tap handler
    if (onTap != null) {
      avatar = GestureDetector(
        onTap: onTap,
        child: avatar,
      );
    }

    return avatar;
  }
}
