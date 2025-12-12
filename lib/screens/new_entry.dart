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
  bool _clearedExistingImage = false;

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

  Future<dynamic> _compressPickedImage() async {
    if (_pickedImage == null) return null;
    // On web we cannot create File objects or compress using native APIs.
    if (kIsWeb) return null;
    try {
      final originalPath = _pickedImage!.path;
      final tmpDir = await getTemporaryDirectory();
      final targetPath = p.join(
        tmpDir.path,
        'lm_upload_${DateTime.now().millisecondsSinceEpoch}${p.extension(originalPath)}',
      );

      final result = await FlutterImageCompress.compressAndGetFile(
        originalPath,
        targetPath,
        minWidth: 800,
        minHeight: 600,
        quality: 88,
        keepExif: true,
      );
      return result;
    } catch (e) {
      return _pickedImage!.path;
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
      dynamic compressed;
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
          imagePath: _clearedExistingImage
              ? null
              : (compressed?.path ?? widget.editLandmark!.imagePath),
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
      print('Error: $e');
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Hero(
                      tag: 'lm_img_${widget.editLandmark?.id ?? 'new_preview'}',
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade200,
                        ),
                        child: _pickedImage != null
                            ? AdaptiveImage(
                                imagePath: _pickedImage!.path,
                                imageBytes: _pickedImageBytes,
                                fit: BoxFit.cover,
                              )
                            : (_clearedExistingImage
                                  ? Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.add_a_photo, size: 36),
                                          SizedBox(height: 6),
                                          Text('Tap to select image'),
                                        ],
                                      ),
                                    )
                                  : (widget.editLandmark?.imagePath != null
                                        ? AdaptiveImage(
                                            imagePath:
                                                widget.editLandmark!.imagePath,
                                            fit: BoxFit.cover,
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: const [
                                                Icon(
                                                  Icons.add_a_photo,
                                                  size: 36,
                                                ),
                                                SizedBox(height: 6),
                                                Text('Tap to select image'),
                                              ],
                                            ),
                                          ))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Replace'),
                      ),
                      const SizedBox(width: 12),
                      if (_pickedImage != null ||
                          widget.editLandmark?.imagePath != null)
                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _pickedImage = null;
                              _pickedImageBytes = null;
                              _clearedExistingImage = true;
                            });
                          },
                          icon: const Icon(Icons.delete_outline),
                          label: const Text('Remove'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                          ),
                        ),
                    ],
                  ),
                ],
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
