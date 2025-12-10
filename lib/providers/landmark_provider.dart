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
      // fallback to local insert
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      final cloned = Landmark(
        id: newId,
        title: landmark.title,
        latitude: landmark.latitude,
        longitude: landmark.longitude,
        imagePath: image?.path ?? landmark.imagePath,
      );
      _items.insert(0, cloned);
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
  }) async {
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
      final idx = _items.indexWhere((e) => e.id == updated.id);
      if (idx != -1) _items[idx] = updated;
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
