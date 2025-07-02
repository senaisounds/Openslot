import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import '../common/colors.dart';

class ImageUtils {
  /// Validates if a URL is valid for image loading
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && 
             (uri.scheme == 'http' || uri.scheme == 'https') &&
             uri.host.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Safe CachedNetworkImage widget that handles empty/invalid URLs
  static Widget safeCachedNetworkImage({
    required String? imageUrl,
    required Widget placeholder,
    required Widget errorWidget,
    BoxFit? fit,
    double? width,
    double? height,
    String? cacheKey,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
    int? memCacheWidth,
    int? maxWidthDiskCache,
    Widget Function(BuildContext, ImageProvider)? imageBuilder,
  }) {
    if (!isValidImageUrl(imageUrl)) {
      return errorWidget;
    }

    return CachedNetworkImage(
      imageUrl: imageUrl!,
      placeholder: (context, url) => placeholder,
      errorWidget: (context, url, error) => errorWidget,
      fit: fit,
      width: width,
      height: height,
      cacheKey: cacheKey,
      fadeInDuration: fadeInDuration ?? const Duration(milliseconds: 250),
      fadeOutDuration: fadeOutDuration ?? const Duration(milliseconds: 150),
      memCacheWidth: memCacheWidth,
      maxWidthDiskCache: maxWidthDiskCache,
      imageBuilder: imageBuilder,
    );
  }

  /// Creates a default placeholder for images
  static Widget createImagePlaceholder({
    Color? backgroundColor,
    IconData? icon,
    Color? iconColor,
    double? iconSize,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      color: backgroundColor ?? AppColors.backgroundDark.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          icon ?? CupertinoIcons.photo,
          color: iconColor ?? AppColors.textSecondary.withValues(alpha: 0.5),
          size: iconSize ?? 40,
        ),
      ),
    );
  }

  /// Creates a user avatar placeholder with initials
  static Widget createAvatarPlaceholder({
    required String name,
    double? size,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final initials = _getInitials(name);
    final avatarSize = size ?? 40.0;
    
    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: backgroundColor ?? _getAvatarColor(name),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontSize: avatarSize * 0.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Get user initials from name
  static String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0].substring(0, 1).toUpperCase();
    } else {
      return '${words[0].substring(0, 1)}${words[1].substring(0, 1)}'.toUpperCase();
    }
  }

  /// Generate a consistent color for avatars based on name
  static Color _getAvatarColor(String name) {
    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.accent,
      const Color(0xFF6366F1), // Indigo
      const Color(0xFF8B5CF6), // Violet
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Emerald
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
      const Color(0xFFEC4899), // Pink
    ];
    
    final hash = name.hashCode.abs();
    return colors[hash % colors.length];
  }
} 