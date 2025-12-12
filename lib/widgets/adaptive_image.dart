import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/mock_api_service.dart';

class AdaptiveImage extends StatefulWidget {
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
  State<AdaptiveImage> createState() => _AdaptiveImageState();
}

class _AdaptiveImageState extends State<AdaptiveImage> {
  Uint8List? _loadedBytes;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.imageBytes != null) {
      _loadedBytes = widget.imageBytes;
    } else if (widget.imagePath != null && widget.imagePath!.startsWith('img_')) {
      _fetchMockImage(widget.imagePath!);
    }
  }

  @override
  void didUpdateWidget(covariant AdaptiveImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageBytes != oldWidget.imageBytes) {
      _loadedBytes = widget.imageBytes;
    } else if (widget.imagePath != oldWidget.imagePath) {
      if (widget.imagePath != null && widget.imagePath!.startsWith('img_')) {
        _fetchMockImage(widget.imagePath!);
      } else {
        _loadedBytes = null;
      }
    }
  }

  Future<void> _fetchMockImage(String id) async {
    setState(() {
      _loading = true;
    });
    try {
      final bytes = await MockApiService().getImageBytes(id);
      if (bytes != null) {
        if (mounted) setState(() => _loadedBytes = Uint8List.fromList(bytes));
      }
    } catch (_) {
      // ignore
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = widget.width;
    final height = widget.height;

    if ((widget.imagePath == null || widget.imagePath!.isEmpty) && _loadedBytes == null) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image, size: 36, color: Colors.grey),
      );
    }

    if (_loadedBytes != null) {
      return Image.memory(
        _loadedBytes!,
        fit: widget.fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return _placeholder(width, height);
        },
      );
    }

    if (widget.imagePath != null &&
        (widget.imagePath!.startsWith('http') ||
            widget.imagePath!.startsWith('https') ||
            widget.imagePath!.startsWith('/'))) {
      String imageUrl = widget.imagePath!;
      if (!imageUrl.startsWith('http')) {
        imageUrl = 'https://labs.anontech.info/cse489/t3${widget.imagePath!.startsWith('/') ? '' : '/'}${widget.imagePath!}';
      }
      return Image.network(
        imageUrl,
        fit: widget.fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) => _placeholder(width, height),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey.shade200,
            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        },
      );
    }

    if (_loading) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return _placeholder(width, height);
  }

  Widget _placeholder(double? width, double? height) => Container(
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
