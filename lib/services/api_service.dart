import 'dart:io';

import 'package:dio/dio.dart';

import '../config.dart';
import '../models/landmark.dart';

class ApiService {
  // Use the baseUrl from config
  static String get baseUrl => ApiConfig.baseUrl;

  late final Dio _dio;

  ApiService({Dio? dio}) {
    _dio =
        dio ??
        Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: Duration(seconds: ApiConfig.requestTimeout),
            receiveTimeout: Duration(seconds: ApiConfig.requestTimeout),
          ),
        );

    // Add logging interceptor if enabled
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

  Future<Landmark> createLandmark(Landmark lm, {File? image}) async {
    try {
      final form = FormData();
      form.fields
        ..add(MapEntry('title', lm.title))
        ..add(MapEntry('lat', lm.latitude.toString()))
        ..add(MapEntry('lon', lm.longitude.toString()));

      if (image != null) {
        final fileName = image.path.split(Platform.pathSeparator).last;
        form.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(image.path, filename: fileName),
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

  Future<Landmark> updateLandmark(Landmark lm, {File? image}) async {
    try {
      final form = FormData();
      form.fields
        ..add(MapEntry('id', lm.id))
        ..add(MapEntry('title', lm.title))
        ..add(MapEntry('lat', lm.latitude.toString()))
        ..add(MapEntry('lon', lm.longitude.toString()))
        ..add(MapEntry('_method', 'PUT'));

      if (image != null) {
        final fileName = image.path.split(Platform.pathSeparator).last;
        form.files.add(
          MapEntry(
            'image',
            await MultipartFile.fromFile(image.path, filename: fileName),
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
