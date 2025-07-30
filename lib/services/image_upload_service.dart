import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'cloudinary_service.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndUploadImage({
    ImageSource source = ImageSource.gallery,
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (image == null) return null;

      if (kIsWeb) {
        // Web platform
        final bytes = await image.readAsBytes();
        return await CloudinaryService.uploadImageBytes(bytes, image.name);
      } else {
        // Mobile platform
        final file = File(image.path);
        return await CloudinaryService.uploadImage(file);
      }
    } catch (e) {
      print('Error picking and uploading image: $e');
      return null;
    }
  }

  static Future<List<String>> pickAndUploadMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int? imageQuality,
    int? limit,
  }) async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
        limit: limit,
      );

      final List<String> uploadedUrls = [];

      for (final image in images) {
        String? url;
        
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          url = await CloudinaryService.uploadImageBytes(bytes, image.name);
        } else {
          final file = File(image.path);
          url = await CloudinaryService.uploadImage(file);
        }

        if (url != null) {
          uploadedUrls.add(url);
        }
      }

      return uploadedUrls;
    } catch (e) {
      print('Error picking and uploading multiple images: $e');
      return [];
    }
  }
}