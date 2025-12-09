import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/landmark.dart';
import '../providers/landmark_provider.dart';
import 'new_entry.dart';

class RecordsListScreen extends StatelessWidget {
  const RecordsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(builder: (context, provider, _) {
      if (provider.loading) {
        return const Center(child: CircularProgressIndicator());
      }

      final items = provider.items;
      if (items.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No landmarks yet', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NewEntryScreen())),
                icon: const Icon(Icons.add),
                label: const Text('Add First Landmark'),
              )
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: provider.loadLandmarks,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final lm = items[i];
            return Dismissible(
              key: ValueKey(lm.id),
              background: Container(
                color: Colors.green,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                child: const Icon(Icons.edit, color: Colors.white),
              ),
              secondaryBackground: Container(
                color: Colors.redAccent,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              confirmDismiss: (direction) async {
                if (direction == DismissDirection.startToEnd) {
                  // Edit
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewEntryScreen(editLandmark: lm)));
                  return false;
                } else {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (c) => AlertDialog(
                      title: const Text('Delete landmark'),
                      content: Text('Delete "${lm.title}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                        TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    await provider.deleteLandmark(lm.id);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
                    return true;
                  }
                  return false;
                }
                return false;
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey.shade200),
                    child: const Icon(Icons.location_city, color: Colors.grey),
                  ),
                  title: Text(lm.title),
                  subtitle: Text('${lm.latitude.toStringAsFixed(4)}, ${lm.longitude.toStringAsFixed(4)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showCardActions(context, lm),
                  ),
                ),
              ),
            );
          },
        ),
      );
    });
  }

  void _showCardActions(BuildContext context, Landmark lm) {
    showModalBottomSheet(
      context: context,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => NewEntryScreen(editLandmark: lm)));
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Delete'),
              onTap: () async {
                Navigator.of(context).pop();
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text('Delete landmark'),
                    content: Text('Delete "${lm.title}"?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancel')),
                      TextButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await Provider.of<LandmarkProvider>(context, listen: false).deleteLandmark(lm.id);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted'), backgroundColor: Colors.green));
                }
              },
            )
          ],
        ),
      ),
    );
  }
}
