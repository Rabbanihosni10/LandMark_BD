import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../models/landmark.dart';
import '../providers/landmark_provider.dart';
import '../widgets/adaptive_image.dart';

class NewEntryScreen extends StatefulWidget {
  final Landmark? editLandmark;

  const NewEntryScreen({Key? key, this.editLandmark}) : super(key: key);

  @override
  State<NewEntryScreen> createState() => _NewEntryScreenState();
}

class _NewEntryScreenState extends State<NewEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  XFile? _pickedImage;
  Uint8List? _pickedImageBytes;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.editLandmark != null) {
      _titleController.text = widget.editLandmark!.title;
      _latController.text = widget.editLandmark!.latitude.toString();
      _lonController.text = widget.editLandmark!.longitude.toString();
    } else {
      _fillWithCurrentLocation();
    }
  }

  Future<void> _fillWithCurrentLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _latController.text = pos.latitude.toString();
      _lonController.text = pos.longitude.toString();
    } catch (e) {
      // ignore and allow manual entry
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file != null) {
      if (kIsWeb) {
        try {
          final bytes = await file.readAsBytes();
          setState(() {
            _pickedImage = file;
            _pickedImageBytes = bytes;
          });
        } catch (e) {
          setState(() {
            _pickedImage = file;
            _pickedImageBytes = null;
          });
        }
      } else {
        setState(() {
          _pickedImage = file;
          _pickedImageBytes = null;
        });
      }
      // Image will be compressed when submitting to avoid extra work here.
    }
  }

  Future<File?> _compressPickedImage() async {
    if (_pickedImage == null) return null;
    // On web we cannot create File objects or compress using native APIs.
    if (kIsWeb) return null;
    try {
      final original = File(_pickedImage!.path);
      final tmpDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tmpDir.path,
        'lm_upload_${DateTime.now().millisecondsSinceEpoch}${p.extension(original.path)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        original.path,
        targetPath,
        minWidth: 800,
        minHeight: 600,
        quality: 88,
        keepExif: true,
      );
      return result;
    } catch (e) {
      return File(_pickedImage!.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final title = _titleController.text.trim();
      final lat = double.parse(_latController.text.trim());
      final lon = double.parse(_lonController.text.trim());

      final provider = Provider.of<LandmarkProvider>(context, listen: false);

      // Handle image for web (bytes) and mobile (File/compressed File)
      List<int>? imageBytes;
      String? imageFilename;
      File? compressed;
      if (kIsWeb) {
        if (_pickedImage != null) {
          // reuse bytes read during pick if available to avoid a second read
          imageBytes = _pickedImageBytes ?? await _pickedImage!.readAsBytes();
          imageFilename = _pickedImage!.name;
        }
      } else {
        compressed = await _compressPickedImage();
      }

      if (widget.editLandmark != null) {
        final updated = Landmark(
          id: widget.editLandmark!.id,
          title: title,
          latitude: lat,
          longitude: lon,
          imagePath: compressed?.path ?? widget.editLandmark!.imagePath,
        );
        await provider.updateLandmark(
          updated,
          image: compressed,
          imageBytes: imageBytes,
          imageFilename: imageFilename,
          rethrowOnFail: true,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final created = Landmark(
          id: 'tmp',
          title: title,
          latitude: lat,
          longitude: lon,
          imagePath: compressed?.path,
        );
        await provider.addLandmark(
          created,
          image: compressed,
          imageBytes: imageBytes,
          imageFilename: imageFilename,
          rethrowOnFail: true,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      // Show error dialog but keep the form open so user can retry
      // Data has been saved locally as fallback
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Server Error'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Data was saved locally, but failed to sync with server:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              const Text(
                'Check your network and try again. Your data will sync when the server is reachable.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      // Show a snackbar to acknowledge local save
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Saved locally | Server sync failed'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.editLandmark != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Landmark' : 'New Landmark')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Title required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latController,
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Latitude required';
                        final n = double.tryParse(v);
                        if (n == null || n < -90 || n > 90)
                          return 'Invalid latitude';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lonController,
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty)
                          return 'Longitude required';
                        final n = double.tryParse(v);
                        if (n == null || n < -180 || n > 180)
                          return 'Invalid longitude';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Image', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.grey.shade200,
                  ),
                  child: _pickedImage != null
                      ? AdaptiveImage(
                          imagePath: _pickedImage!.path,
                          imageBytes: _pickedImageBytes,
                        )
                      : (widget.editLandmark?.imagePath != null
                            ? AdaptiveImage(
                                imagePath: widget.editLandmark!.imagePath,
                              )
                            : Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.add_a_photo, size: 36),
                                    SizedBox(height: 6),
                                    Text('Tap to select image'),
                                  ],
                                ),
                              )),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update' : 'Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
