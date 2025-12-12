import 'package:dio/dio.dart';
import '../config.dart';
import '../models/landmark.dart';
import 'mock_api_service.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  late final Dio _dio;
  late final MockApiService _mockApi;

  ApiService({Dio? dio}) {
    _mockApi = MockApiService();
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: Duration(seconds: ApiConfig.requestTimeout),
            receiveTimeout: Duration(seconds: ApiConfig.requestTimeout),
          ),
        );

    if (ApiConfig.enableLogging) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => print(obj),
        ),
      );
    }
  }

  Future<List<Landmark>> fetchLandmarks() async {
    if (ApiConfig.useLocalMockApi) return _mockApi.fetchLandmarks();
    try {
      final resp = await _dio.get(ApiConfig.apiEndpoint);
      if (resp.statusCode == 200) {
        final data = resp.data as List<dynamic>?;
        if (data == null || data.isEmpty) return [];
        return data
            .map((e) => Landmark.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception(
        'Failed to load landmarks: ${resp.statusCode} ${resp.statusMessage}',
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to load landmarks: $e');
    }
  }

  Future<Landmark> createLandmark(
    Landmark lm, {
    dynamic imageFile,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    if (ApiConfig.useLocalMockApi) {
      return _mockApi.createLandmark(
        lm,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
    }
    try {
      final form = FormData();
      form.fields
        ..add(MapEntry('title', lm.title))
        ..add(MapEntry('lat', lm.latitude.toString()))
        ..add(MapEntry('lon', lm.longitude.toString()));

      if (imageFile != null) {
        final fileName = imageFile.path.split(RegExp(r'[/\\]')).last;
        form.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
      } else if (imageBytes != null && imageFilename != null) {
        form.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(imageBytes, filename: imageFilename),
          ),
        );
      }

      final resp = await _dio.post(ApiConfig.apiEndpoint, data: form);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        return Landmark.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to create landmark: ${resp.statusCode} ${resp.statusMessage}',
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to create landmark: $e');
    }
  }

  Future<Landmark> updateLandmark(
    Landmark lm, {
    dynamic imageFile,
    List<int>? imageBytes,
    String? imageFilename,
  }) async {
    if (ApiConfig.useLocalMockApi) {
      return _mockApi.updateLandmark(
        lm,
        imageBytes: imageBytes,
        imageFilename: imageFilename,
      );
    }
    try {
      if (imageFile == null && (imageBytes == null || imageFilename == null)) {
        final data = {
          'id': lm.id,
          'title': lm.title,
          'lat': lm.latitude.toString(),
          'lon': lm.longitude.toString(),
        };
        final resp = await _dio.put(
          ApiConfig.apiEndpoint,
          data: data,
          options: Options(contentType: Headers.formUrlEncodedContentType),
        );
        if (resp.statusCode == 200) {
          return Landmark.fromJson(resp.data as Map<String, dynamic>);
        }
        throw Exception(
          'Failed to update landmark: ${resp.statusCode} ${resp.statusMessage}',
        );
      }

      final form = FormData();
      form.fields
        ..add(MapEntry('id', lm.id))
        ..add(MapEntry('title', lm.title))
        ..add(MapEntry('lat', lm.latitude.toString()))
        ..add(MapEntry('lon', lm.longitude.toString()))
        ..add(MapEntry('_method', 'PUT'));

      if (imageFile != null) {
        final fileName = imageFile.path.split(RegExp(r'[/\\]')).last;
        form.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(imageFile.path, filename: fileName),
          ),
        );
      } else if (imageBytes != null && imageFilename != null) {
        form.files.add(
          MapEntry(
            'image',
            MultipartFile.fromBytes(imageBytes, filename: imageFilename),
          ),
        );
      }

      final resp = await _dio.post(ApiConfig.apiEndpoint, data: form);
      if (resp.statusCode == 200) {
        return Landmark.fromJson(resp.data as Map<String, dynamic>);
      }
      throw Exception(
        'Failed to update landmark: ${resp.statusCode} ${resp.statusMessage}',
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to update landmark: $e');
    }
  }

  Future<void> deleteLandmark(String id) async {
    if (ApiConfig.useLocalMockApi) {
      return _mockApi.deleteLandmark(id);
    }
    try {
      final resp = await _dio.post(
        ApiConfig.apiEndpoint,
        data: FormData.fromMap({'id': id, '_method': 'DELETE'}),
      );
      if (resp.statusCode == 200) return;
      throw Exception(
        'Failed to delete: ${resp.statusCode} ${resp.statusMessage}',
      );
    } on DioException catch (e) {
      print('DioException: ${e.message}');
      throw Exception('Network error: ${e.message}');
    } catch (e) {
      print('Exception: $e');
      throw Exception('Failed to delete landmark: $e');
    }
  }
}
