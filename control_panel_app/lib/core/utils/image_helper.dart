// lib/core/utils/image_helper.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImageHelper {
  static const String defaultPropertyImage = 'assets/images/default_property.jpg';
  static const String defaultUserAvatar = 'assets/images/default_avatar.png';
  
  static String getValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return defaultPropertyImage;
    }
    
    // تجنب استخدام placeholder.com عند عدم وجود اتصال
    if (url.contains('placeholder.com')) {
      return defaultPropertyImage;
    }
    
    return url;
  }
  
  static Widget buildCachedImage({
    required String? imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    final url = getValidImageUrl(imageUrl);
    
    // إذا كان URL محلي (asset)
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return errorWidget ?? _buildDefaultErrorWidget();
        },
      );
    }
    
    // إذا كان URL عادي
    return CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultErrorWidget(),
    );
  }
  
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  static Widget _buildDefaultErrorWidget() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );
  }
}