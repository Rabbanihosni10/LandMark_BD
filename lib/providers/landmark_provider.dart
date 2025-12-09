import 'dart:async';

import 'package:flutter/material.dart';
import '../models/landmark.dart';

// Simple in-memory provider that simulates network calls.
// Replace simulated delays and local storage with real API calls using
// Retrofit/dio and a Room-like local database for offline caching.
class LandmarkProvider extends ChangeNotifier {
  final List<Landmark> _items = [];

  bool isOnline = true; // Placeholder; toggle based on connectivity
  bool _loading = false;

  List<Landmark> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  LandmarkProvider() {
    loadLandmarks();
  }

  Future<void> loadLandmarks() async {
    _loading = true;
    notifyListeners();

    // Simulate network GET /api.php
    await Future.delayed(const Duration(milliseconds: 600));

    // Sample seeded data for demonstration
    _items.clear();
    _items.addAll([
      Landmark(
        id: '1',
        title: 'Lalbagh Fort',
        latitude: 23.7146,
        longitude: 90.4058,
        imagePath: null,
      ),
      Landmark(
        id: '2',
        title: 'Ahsan Manzil',
        latitude: 23.7257,
        longitude: 90.3980,
        imagePath: null,
      ),
    ]);

    _loading = false;
    notifyListeners();
  }

  Future<Landmark> addLandmark(Landmark landmark) async {
    _loading = true;
    notifyListeners();

    // Simulate POST /api.php (multipart for image)
    await Future.delayed(const Duration(milliseconds: 800));

    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final cloned = Landmark(
      id: newId,
      title: landmark.title,
      latitude: landmark.latitude,
      longitude: landmark.longitude,
      imagePath: landmark.imagePath,
    );

    _items.insert(0, cloned);
    _loading = false;
    notifyListeners();
    return cloned;
  }

  Future<Landmark> updateLandmark(Landmark updated) async {
    _loading = true;
    notifyListeners();

    // Simulate PUT /api.php
    await Future.delayed(const Duration(milliseconds: 700));

    final idx = _items.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _items[idx] = updated;
    }

    _loading = false;
    notifyListeners();
    return updated;
  }

  Future<void> deleteLandmark(String id) async {
    _loading = true;
    notifyListeners();

    // Simulate DELETE /api.php
    await Future.delayed(const Duration(milliseconds: 600));

    _items.removeWhere((e) => e.id == id);
    _loading = false;
    notifyListeners();
  }
}
