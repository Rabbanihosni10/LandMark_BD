import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/landmark.dart';
import '../providers/landmark_provider.dart';

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
      setState(() {
        _pickedImage = file;
      });
      // TODO: resize image to 800x600 before uploading using flutter_image_compress or image
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

      if (widget.editLandmark != null) {
        final updated = Landmark(
          id: widget.editLandmark!.id,
          title: title,
          latitude: lat,
          longitude: lon,
          imagePath: _pickedImage?.path ?? widget.editLandmark!.imagePath,
        );
        await provider.updateLandmark(updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Updated'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final created = Landmark(
          id: 'tmp',
          title: title,
          latitude: lat,
          longitude: lon,
          imagePath: _pickedImage?.path,
        );
        await provider.addLandmark(created);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Created'),
            backgroundColor: Colors.green,
          ),
        );
      }

      Navigator.of(context).pop();
    } catch (e) {
      await showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to save: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(c).pop(),
              child: const Text('Dismiss'),
            ),
          ],
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
              Text('Image', style: Theme.of(context).textTheme.subtitle1),
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
                      ? Image.file(File(_pickedImage!.path), fit: BoxFit.cover)
                      : (widget.editLandmark?.imagePath != null
                            ? Image.file(
                                File(widget.editLandmark!.imagePath!),
                                fit: BoxFit.cover,
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
