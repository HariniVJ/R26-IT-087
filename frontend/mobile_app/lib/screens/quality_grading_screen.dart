import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/prediction_result.dart';
import '../services/tflite_service.dart';

class QualityScreen extends StatefulWidget {
  const QualityScreen({super.key});

  @override
  State<QualityScreen> createState() => _QualityScreenState();
}

class _QualityScreenState extends State<QualityScreen> {
  final TfliteService _tfliteService = TfliteService();
  final ImagePicker _picker = ImagePicker();

  File? _image;
  PredictionResult? _result;
  bool _isLoading = false;
  bool _modelLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadModel();
  }

  Future<void> _loadModel() async {
    await _tfliteService.loadModel();
    setState(() {
      _modelLoaded = true;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_modelLoaded) return;

    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
      _result = null;
      _isLoading = true;
    });

    try {
      final prediction = await _tfliteService.predict(_image!);

      setState(() {
        _result = prediction;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    _tfliteService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qualityText = _result?.quality.replaceAll('_', ' ').toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fruit Quality Grading'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _image!,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                height: 220,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('No image selected'),
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    child: const Text('Upload Image'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(ImageSource.camera),
                    child: const Text('Camera'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            if (_isLoading)
              const CircularProgressIndicator(),

            if (_result != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quality: $qualityText'),
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${_result!.confidence.toStringAsFixed(2)}%',
                      ),
                      const SizedBox(height: 8),
                      Text('Recommendation: ${_result!.recommendation}'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}