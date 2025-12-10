import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Widget that displays an image from either a local file path or a network URL
class AdaptiveImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final double? width;
  final double? height;

  const AdaptiveImage({
    Key? key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (imagePath == null || imagePath!.isEmpty) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 36, color: Colors.grey),
      );
    }

    // Check if it's a URL (starts with http, https, or /)
    if (imagePath!.startsWith('http') ||
        imagePath!.startsWith('https') ||
        imagePath!.startsWith('/')) {
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

    // On web, we can't use Image.file(), show a placeholder
    if (kIsWeb) {
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
              Text(
                'Image preview not available\non web',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Otherwise treat as local file path (only on mobile/desktop)
    return Image.file(
      File(imagePath!),
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
}
