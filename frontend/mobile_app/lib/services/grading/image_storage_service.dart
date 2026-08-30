// lib/services/grading/image_storage_service.dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

/// Uploads grading photos to Firebase Storage and returns a public URL
/// to store alongside the grading result. Upload is best-effort — if it
/// fails (e.g. no network), grading still completes without a photo.
class ImageStorageService {
  ImageStorageService._();
  static final ImageStorageService instance = ImageStorageService._();

  Future<String?> uploadGradingImage(File imageFile, String userId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('quality_results')
          .child(userId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      final task = await ref.putFile(imageFile);
      return await task.ref.getDownloadURL();
    } catch (e) {
      return null; // grading still proceeds without a photo
    }
  }
}