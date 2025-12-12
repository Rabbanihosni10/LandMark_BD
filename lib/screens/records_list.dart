import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/landmark_provider.dart';
import 'new_entry.dart';
import '../widgets/landmark_card.dart';
import 'landmark_detail.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Consumer<LandmarkProvider>(
      builder: (context, provider, _) {
        if (provider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = provider.items;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_off, size: 64, color: colorScheme.outline),
                const SizedBox(height: 16),
                Text(
                  'No landmarks yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap below to add your first landmark',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const NewEntryScreen()),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Add First Landmark'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: provider.loadLandmarks,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final lm = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: LandmarkCard(
                  landmark: lm,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LandmarkDetailScreen(landmark: lm),
                      ),
                    );
                  },
                  onEdit: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => NewEntryScreen(editLandmark: lm),
                      ),
                    );
                  },
                  onDelete: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete landmark'),
                        content: Text('Delete "${lm.title}"?'),
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
                      await provider.deleteLandmark(lm.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Actions are handled inline in the card callbacks now.
}
