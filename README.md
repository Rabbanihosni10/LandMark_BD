# Bangladesh Landmark Manager

A Flutter application for managing and viewing Bangladesh landmarks with REST API integration.

## Features

- View landmarks on an interactive map
- Create, read, update, and delete landmarks
- Image upload support for landmarks
- Geolocation-based landmark discovery
- Offline fallback with local data caching

## REST API Integration

This app uses the Bangladesh Landmark REST API:

**Base URL:** `https://labs.anontech.info/cse489/t3`

### API Endpoints

- **GET `/api.php`** - Fetch all landmarks
- **POST `/api.php`** - Create a new landmark
- **POST `/api.php` (with `_method=PUT`)** - Update a landmark
- **POST `/api.php` (with `_method=DELETE`)** - Delete a landmark

### API Configuration

The API base URL and endpoints are configured in `lib/config.dart`:

```dart
class ApiConfig {
  static const String baseUrl = 'https://labs.anontech.info/cse489/t3';
  static const String apiEndpoint = '/api.php';
  static const int requestTimeout = 30; // seconds
  static const bool enableLogging = true; // Enable debug logging
}
```

To change the API endpoint or timeout, update these values in `lib/config.dart`.

### Landmark Model

Each landmark has the following fields:

```json
{
  "id": 341,
  "title": "Landmark Name",
  "lat": 23.8103,
  "lon": 90.4124983,
  "image": "images/img_69394929322de7.80048093.jpg"
}
```

## Getting Started

### Prerequisites

- Flutter SDK (3.9.2 or higher)
- Dart SDK
- A compatible IDE (VS Code, Android Studio, etc.)

### Installation

1. Clone the repository:

   ```bash
   git clone <repository_url>
   cd landmark_bd
   ```

2. Install dependencies:

   ```bash
   flutter pub get
   ```

3. Run the application:
   ```bash
   flutter run
   ```

### Platform-Specific Setup

#### Android

- No additional setup required. The app will use your device's internet connection.

#### iOS

- No additional setup required. The app will use your device's internet connection.

#### Web

- Run the web version:
  ```bash
  flutter run -d chrome
  ```

## Project Structure

```
lib/
├── config.dart                 # API and app configuration
├── main.dart                   # App entry point
├── models/
│   └── landmark.dart          # Landmark data model
├── providers/
│   └── landmark_provider.dart  # State management (Provider)
├── screens/
│   ├── splash.dart            # Splash screen
│   ├── overview_map.dart      # Map view screen
│   ├── records_list.dart      # Landmarks list screen
│   └── new_entry.dart         # Add/edit landmark screen
└── services/
    └── api_service.dart       # REST API client (Dio)
```

## API Service Usage

The `ApiService` class handles all REST API communication:

```dart
// Fetch landmarks
List<Landmark> landmarks = await apiService.fetchLandmarks();

// Create landmark
Landmark newLandmark = await apiService.createLandmark(landmark, image: imageFile);

// Update landmark
Landmark updated = await apiService.updateLandmark(landmark, image: imageFile);

// Delete landmark
await apiService.deleteLandmark(landmarkId);
```

## Error Handling

The app includes comprehensive error handling:

- Network errors are caught and displayed to the user
- Fallback to local cached data when the API is unavailable
- Detailed error messages for debugging (when logging is enabled)

## Dependencies

Key dependencies used in this project:

- **provider** (^6.0.5) - State management
- **dio** (^5.2.1) - HTTP client
- **flutter_map** (^4.0.0) - Interactive map widget
- **image_picker** (^0.8.7+4) - Image selection
- **geolocator** (^9.0.2) - Geolocation services
- **intl** (^0.18.0) - Internationalization
- **path_provider** (^2.0.15) - File system access
- **flutter_image_compress** (^1.1.0) - Image compression

## Debugging

### Enable API Logging

To see detailed API request/response logs, ensure `enableLogging` is set to `true` in `lib/config.dart`:

```dart
static const bool enableLogging = true;
```

### Check API Connectivity

Test the API directly:

```bash
curl https://labs.anontech.info/cse489/t3/api.php
```

## Troubleshooting

### API Connection Issues

- Verify your internet connection
- Check that the API base URL in `config.dart` is correct
- Ensure the API server is online (test with curl)

### Image Upload Issues

- Ensure you have storage permissions on your device
- Check that the image file exists and is accessible
- Verify the image format (JPG, PNG, etc.) is supported

### State Management Issues

- Ensure `LandmarkProvider` is properly initialized in `main.dart`
- Check that all consumers are wrapped with `Consumer<LandmarkProvider>`

## Building for Production

To build a production APK for Android:

```bash
flutter build apk --release
```

To build a production app bundle:

```bash
flutter build appbundle --release
```

For iOS:

```bash
flutter build ios --release
```

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dio Documentation](https://pub.dev/packages/dio)
- [Provider Documentation](https://pub.dev/packages/provider)
- [Flutter Map Documentation](https://flutter-map.dev)

