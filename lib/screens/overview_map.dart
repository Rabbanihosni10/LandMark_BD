import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../providers/landmark_provider.dart';
import '../models/landmark.dart';
import 'package:intl/intl.dart';
import 'new_entry.dart';

class OverviewMapScreen extends StatelessWidget {
  const OverviewMapScreen({Key? key}) : super(key: key);

  static final LatLng _bangladeshCenter = LatLng(23.6850, 90.3563);

  @override
  Widget build(BuildContext context) {
    return Consumer<LandmarkProvider>(
      builder: (context, provider, _) {
        return FlutterMap(
          options: MapOptions(
            center: _bangladeshCenter,
            zoom: 6.5,
            onTap: (_, __) {},
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
              subdomains: const ['a', 'b', 'c'],
              userAgentPackageName: 'com.example.landmark_bd',
            ),
            MarkerLayer(
              markers: provider.items.map((Landmark lm) {
                return Marker(
                  width: 56,
                  height: 56,
                  point: LatLng(lm.latitude, lm.longitude),
                  builder: (ctx) => GestureDetector(
                    onTap: () => _showMarkerSheet(context, lm),
                    child: Column(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 36,
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  void _showMarkerSheet(BuildContext context, Landmark lm) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lm.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat.yMMMd().format(lm.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 88,
                    height: 66,
                    color: Colors.grey.shade200,
                    child: lm.imagePath != null
                        ? Image.file(File(lm.imagePath!), fit: BoxFit.cover)
                        : const Icon(Icons.image, size: 36, color: Colors.grey),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Lat: ${lm.latitude.toStringAsFixed(4)}, Lon: ${lm.longitude.toStringAsFixed(4)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Navigate to edit mode
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => NewEntryScreen(editLandmark: lm),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Delete landmark'),
                          content: Text(
                            'Delete "${lm.title}"? This cannot be undone.',
                          ),
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
                        ).deleteLandmark(lm.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Deleted'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    label: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
