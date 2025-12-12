import '../models/landmark.dart';

class MockApiService {
  static final MockApiService _instance = MockApiService._internal();
  late List<Landmark> _mockData;
  late Map<String, List<int>> _imageStore;

  factory MockApiService() {
    return _instance;
  }

  MockApiService._internal() {
    _imageStore = {};
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

  Future<String?> _saveImage(
    List<int>? imageBytes,
    String? imageFilename,
  ) async {
    if (imageBytes != null && imageFilename != null) {
      try {
        final imageId =
            'img_${DateTime.now().millisecondsSinceEpoch}_$imageFilename';
        _imageStore[imageId] = imageBytes;
        return imageId;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Return stored image bytes for a mock image id (e.g. 'img_...').
  Future<List<int>?> getImageBytes(String imageId) async {
    // small simulated delay to mimic network/file read
    await Future.delayed(const Duration(milliseconds: 120));
    return _imageStore[imageId];
  }

  Future<List<Landmark>> fetchLandmarks() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockData);
  }

  Future<Landmark> createLandmark(
    Landmark lm, {
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final imagePath = await _saveImage(imageBytes, imageFilename);

    final newId = 'mock_${DateTime.now().millisecondsSinceEpoch}';
    final created = Landmark(
      id: newId,
      title: lm.title,
      latitude: lm.latitude,
      longitude: lm.longitude,
      imagePath: imagePath,
    );
    _mockData.insert(0, created);
    return created;
  }

  Future<Landmark> updateLandmark(
    Landmark lm, {
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));

    final idx = _mockData.indexWhere((e) => e.id == lm.id);
    if (idx == -1) {
      throw Exception('Landmark not found');
    }

    String? imagePath = _mockData[idx].imagePath;
    if (imageBytes != null && imageFilename != null) {
      imagePath = await _saveImage(imageBytes, imageFilename) ?? imagePath;
    }

    final updated = Landmark(
      id: lm.id,
      title: lm.title,
      latitude: lm.latitude,
      longitude: lm.longitude,
      imagePath: imagePath,
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
