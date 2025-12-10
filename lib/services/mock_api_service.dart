import 'dart:io';
import '../models/landmark.dart';

class MockApiService {
  static final MockApiService _instance = MockApiService._internal();
  late List<Landmark> _mockData;

  factory MockApiService() {
    return _instance;
  }

  MockApiService._internal() {
    _mockData = [
      Landmark(
        id: 'mock_1',
        title: 'Lalbagh Fort',
        latitude: 23.7146,
        longitude: 90.4058,
        imagePath: null,
      ),
      Landmark(
        id: 'mock_2',
        title: 'Ahsan Manzil',
        latitude: 23.7257,
        longitude: 90.3980,
        imagePath: null,
      ),
      Landmark(
        id: 'mock_3',
        title: 'Star Mosque',
        latitude: 23.7098,
        longitude: 90.3677,
        imagePath: null,
      ),
    ];
  }

  Future<List<Landmark>> fetchLandmarks() async {
    await Future.delayed(
      const Duration(milliseconds: 500),
    ); // Simulate network delay
    return List.from(_mockData);
  }

  Future<Landmark> createLandmark(
    Landmark lm, {
    File? imageFile,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final newId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final created = Landmark(
      id: newId,
      title: lm.title,
      latitude: lm.latitude,
      longitude: lm.longitude,
      imagePath: imageFile?.path ?? lm.imagePath,
    );
    _mockData.insert(0, created);
    return created;
  }

  Future<Landmark> updateLandmark(
    Landmark lm, {
    File? imageFile,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final idx = _mockData.indexWhere((e) => e.id == lm.id);
    if (idx == -1) {
      throw Exception('Landmark not found');
    }

    final updated = Landmark(
      id: lm.id,
      title: lm.title,
      latitude: lm.latitude,
      longitude: lm.longitude,
      imagePath: imageFile?.path ?? _mockData[idx].imagePath,
    );
    _mockData[idx] = updated;
    return updated;
  }

  Future<void> deleteLandmark(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final idx = _mockData.indexWhere((e) => e.id == id);
    if (idx == -1) {
      throw Exception('Landmark not found');
    }
    _mockData.removeAt(idx);
  }
}
