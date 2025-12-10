import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../models/landmark.dart';
import '../services/api_service.dart';

// Provider that uses ApiService to perform CRUD operations.
class LandmarkProvider extends ChangeNotifier {
  final List<Landmark> _items = [];
  final ApiService _api;

  bool isOnline = true; // Placeholder; update via connectivity listener
  bool _loading = false;

  List<Landmark> get items => List.unmodifiable(_items);
  bool get loading => _loading;

  LandmarkProvider({ApiService? api}) : _api = api ?? ApiService() {
    loadLandmarks();
  }

  Future<void> loadLandmarks() async {
    _loading = true;
    notifyListeners();
    try {
      final list = await _api.fetchLandmarks();
      _items
        ..clear()
        ..addAll(list);
    } catch (e) {
      // Fallback: keep current in-memory items or seed sample data
      if (_items.isEmpty) {
        _items.addAll([
          Landmark(
            id: '1',
            title: 'Lalbagh Fort',
            latitude: 23.7146,
            longitude: 90.4058,
          ),
          Landmark(
            id: '2',
            title: 'Ahsan Manzil',
            latitude: 23.7257,
            longitude: 90.3980,
          ),
        ]);
      }
    }
    _loading = false;
    notifyListeners();
  }

  Future<Landmark> addLandmark(
    Landmark landmark, {
    File? image,
    List<int>? imageBytes,
    String? imageFilename,
    bool rethrowOnFail = false,
  }) async {
    _loading = true;
    notifyListeners();
    try {
      final created = await _api.createLandmark(
        landmark,
        imageFile: image,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
      _items.insert(0, created);
      return created;
    } catch (e) {
      // If rethrowOnFail is true, insert locally AND rethrow so UI shows error + fallback
      // If false (default), silently insert locally (offline fallback)
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final cloned = Landmark(
        id: newId,
        title: landmark.title,
        latitude: landmark.latitude,
        longitude: landmark.longitude,
        imagePath: image?.path ?? landmark.imagePath,
      );
      _items.insert(0, cloned);
      if (rethrowOnFail)
        rethrow; // Insert first, then rethrow so data is saved locally
      return cloned;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Landmark> updateLandmark(
    Landmark updated, {
    File? image,
    List<int>? imageBytes,
    String? imageFilename,
    bool rethrowOnFail = false,
  }) async {
    // allow callers to pass a rethrow flag in a migrated signature
    // (backwards compatible: non-named args won't set this)
    // NOTE: callers should pass via named parameter; this local var will be overwritten

    _loading = true;
    notifyListeners();
    try {
      final res = await _api.updateLandmark(
        updated,
        imageFile: image,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
      final idx = _items.indexWhere((e) => e.id == res.id);
      if (idx != -1) _items[idx] = res;
      return res;
    } catch (e) {
      // Insert locally first, then rethrow if requested (so data is saved + user sees error)
      final idx = _items.indexWhere((e) => e.id == updated.id);
      if (idx != -1) _items[idx] = updated;
      if (rethrowOnFail) rethrow;
      return updated;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteLandmark(String id) async {
    _loading = true;
    notifyListeners();
    try {
      await _api.deleteLandmark(id);
      _items.removeWhere((e) => e.id == id);
    } catch (e) {
      // fallback: remove locally
      _items.removeWhere((e) => e.id == id);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
