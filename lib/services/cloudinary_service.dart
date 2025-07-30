import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';

class CloudinaryService {
  static const String cloudName = 'your-cloud-name';
  static const String apiKey = 'your-api-key';
  static const String apiSecret = 'your-api-secret';
  static const String uploadPreset = 'your-upload-preset';

  // Upload image file (mobile)
  static Future<String?> uploadImage(File imageFile) async {
    if (kIsWeb) {
      throw UnsupportedError('Use uploadImageBytes for web platform');
    }
    
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
    }
    return null;
  }

  // Upload image bytes (web)
  static Future<String?> uploadImageBytes(Uint8List imageBytes, String fileName) async {
    try {
      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      
      final request = http.MultipartRequest('POST', url);
      request.fields['upload_preset'] = uploadPreset;
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
      ));

      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'];
      }
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
    }
    return null;
  }

  // Universal upload method
  static Future<String?> uploadImageUniversal({
    File? imageFile,
    Uint8List? imageBytes,
    String? fileName,
  }) async {
    if (kIsWeb) {
      if (imageBytes != null && fileName != null) {
        return uploadImageBytes(imageBytes, fileName);
      }
    } else {
      if (imageFile != null) {
        return uploadImage(imageFile);
      }
    }
    return null;
  }

  static String getOptimizedUrl(String originalUrl, {
    int? width,
    int? height,
    String quality = 'auto',
    String format = 'auto',
  }) {
    if (!originalUrl.contains('cloudinary.com')) {
      return originalUrl;
    }
    
    final transformations = <String>[];
    
    if (width != null) transformations.add('w_$width');
    if (height != null) transformations.add('h_$height');
    transformations.add('q_$quality');
    transformations.add('f_$format');
    
    return originalUrl.replaceFirst(
      '/upload/',
      '/upload/${transformations.join(',')}/');
  }

  // Get thumbnail URL
  static String getThumbnailUrl(String originalUrl, {int size = 200}) {
    return getOptimizedUrl(
      originalUrl,
      width: size,
      height: size,
      quality: 'auto',
    );
  }

  // Get responsive URLs for different screen sizes
  static Map<String, String> getResponsiveUrls(String originalUrl) {
    return {
      'thumbnail': getOptimizedUrl(originalUrl, width: 200, height: 200),
      'small': getOptimizedUrl(originalUrl, width: 400, height: 400),
      'medium': getOptimizedUrl(originalUrl, width: 800, height: 800),
      'large': getOptimizedUrl(originalUrl, width: 1200, height: 1200),
      'original': originalUrl,
    };
  }
}
