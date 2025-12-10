import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget that displays an image from either a local file path or a network URL
class AdaptiveImage extends StatelessWidget {
  final String? imagePath;
  final Uint8List? imageBytes;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AdaptiveImage({
    Key? key,
    this.imagePath,
    this.imageBytes,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if ((imagePath == null || imagePath!.isEmpty) && imageBytes == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 36, color: Colors.grey),
      );
    }

    // If image bytes were provided (useful on web), show them first
    if (imageBytes != null) {
      return Image.memory(
        imageBytes!,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
          );
        },
      );
    }

    // Check if it's a URL (starts with http, https, or /)
    if (imagePath != null &&
        (imagePath!.startsWith('http') ||
            imagePath!.startsWith('https') ||
            imagePath!.startsWith('/'))) {
      // Construct full URL if it's a relative path from API
      String imageUrl = imagePath!;
      if (!imageUrl.startsWith('http')) {
        imageUrl =
            'https://labs.anontech.info/cse489/t3${imagePath!.startsWith('/') ? '' : '/'}$imagePath';
      }

      return Image.network(
        imageUrl,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Icon(Icons.broken_image, size: 36, color: Colors.grey),
          );
        },
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    // If we reached here and we don't have bytes or a network URL,
    // attempt to show a simple placeholder (avoids importing dart:io
    // which is unsupported on web). On non-web platforms a better
    // local-file preview could be added later with conditional imports.
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 36, color: Colors.grey),
            SizedBox(height: 8),
            Text('Image preview not available', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
