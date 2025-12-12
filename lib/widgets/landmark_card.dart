import 'package:flutter/material.dart';

import '../models/landmark.dart';
import 'adaptive_image.dart';

class LandmarkCard extends StatelessWidget {
  final Landmark landmark;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const LandmarkCard({
    Key? key,
    required this.landmark,
    this.onTap,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Hero(
              tag: 'lm_img_${landmark.id}',
              child: SizedBox(
                width: 120,
                height: 96,
                child: landmark.imagePath != null
                    ? AdaptiveImage(imagePath: landmark.imagePath)
                    : Container(
                        color: cs.primaryContainer,
                        child: Icon(Icons.location_on, color: cs.primary),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      landmark.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📍 ${landmark.latitude.toStringAsFixed(4)}, ${landmark.longitude.toStringAsFixed(4)}',
                      style: TextStyle(color: cs.outline),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(onPressed: onEdit, icon: const Icon(Icons.edit)),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
