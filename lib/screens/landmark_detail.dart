import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/landmark.dart';
import '../providers/landmark_provider.dart';
import '../widgets/adaptive_image.dart';

class LandmarkDetailScreen extends StatelessWidget {
  final Landmark landmark;

  const LandmarkDetailScreen({Key? key, required this.landmark})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(landmark.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      // reuse the NewEntry screen for edit
                      // deferred import to avoid cycle
                      // the route will be created by caller if needed
                      Container(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'lm_img_${landmark.id}',
              child: SizedBox(
                height: 280,
                child: AdaptiveImage(imagePath: landmark.imagePath),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              landmark.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Latitude: ${landmark.latitude}'),
            Text('Longitude: ${landmark.longitude}'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete landmark'),
                    content: Text('Delete "${landmark.title}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(c).pop(true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await Provider.of<LandmarkProvider>(
                    context,
                    listen: false,
                  ).deleteLandmark(landmark.id);
                  if (context.mounted) Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
              style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            ),
          ],
        ),
      ),
    );
  }
}
