import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'ai_service.dart';

class TurnJSService {
  static const String _convertEndpoint = '/convert-pdf-to-images';

  /// Convert PDF file to images for Turn.js flipbook
  static Future<Map<String, dynamic>> convertPdfToImages(File pdfFile) async {
    try {
      final baseUrl = AIService.baseUrl;
      final url = Uri.parse('$baseUrl$_convertEndpoint');

      print('🔄 Converting PDF to images: ${pdfFile.path}');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add PDF file
      final fileBytes = await pdfFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: pdfFile.path.split('/').last,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 PDF conversion response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ PDF converted successfully: ${data['totalPages']} pages');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('PDF conversion failed: ${error['error']}');
      }
    } catch (e) {
      print('❌ PDF conversion error: $e');
      throw Exception('Failed to convert PDF: $e');
    }
  }

  /// Convert PDF from file picker to images
  static Future<Map<String, dynamic>> convertPdfFromPicker() async {
    try {
      // Pick PDF file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw Exception('No file selected');
      }

      final platformFile = result.files.first;
      
      // For web platform
      if (platformFile.bytes != null) {
        return await convertPdfFromBytes(
          platformFile.bytes!,
          platformFile.name,
        );
      }
      
      // For mobile/desktop platforms
      if (platformFile.path != null) {
        final file = File(platformFile.path!);
        return await convertPdfToImages(file);
      }

      throw Exception('Unable to read selected file');
    } catch (e) {
      print('❌ PDF picker conversion error: $e');
      throw Exception('Failed to convert PDF from picker: $e');
    }
  }

  /// Convert PDF from bytes (for web platform)
  static Future<Map<String, dynamic>> convertPdfFromBytes(
    List<int> pdfBytes,
    String filename,
  ) async {
    try {
      final baseUrl = AIService.baseUrl;
      final url = Uri.parse('$baseUrl$_convertEndpoint');

      print('🔄 Converting PDF bytes to images: $filename');

      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add PDF bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        pdfBytes,
        filename: filename,
      );
      request.files.add(multipartFile);

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📡 PDF bytes conversion response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ PDF bytes converted successfully: ${data['totalPages']} pages');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw Exception('PDF bytes conversion failed: ${error['error']}');
      }
    } catch (e) {
      print('❌ PDF bytes conversion error: $e');
      throw Exception('Failed to convert PDF bytes: $e');
    }
  }

  /// Validate PDF conversion result
  static bool isValidConversionResult(Map<String, dynamic> result) {
    return result.containsKey('success') &&
           result['success'] == true &&
           result.containsKey('pages') &&
           result['pages'] is List &&
           (result['pages'] as List).isNotEmpty;
  }

  /// Extract pages data from conversion result
  static List<Map<String, dynamic>> extractPagesData(Map<String, dynamic> result) {
    if (!isValidConversionResult(result)) {
      throw Exception('Invalid conversion result');
    }

    final pages = result['pages'] as List;
    return pages.map((page) => page as Map<String, dynamic>).toList();
  }

  /// Get total pages from conversion result
  static int getTotalPages(Map<String, dynamic> result) {
    if (!isValidConversionResult(result)) {
      return 0;
    }
    return result['totalPages'] ?? 0;
  }

  /// Check if page has valid image URL
  static bool isPageValid(Map<String, dynamic> page) {
    return page.containsKey('imageUrl') &&
           page['imageUrl'] != null &&
           page['imageUrl'].toString().isNotEmpty &&
           !page.containsKey('error');
  }

  /// Filter out invalid pages
  static List<Map<String, dynamic>> filterValidPages(List<Map<String, dynamic>> pages) {
    return pages.where((page) => isPageValid(page)).toList();
  }

  /// Create flipbook pages data for Turn.js
  static List<Map<String, dynamic>> createFlipbookPages(Map<String, dynamic> conversionResult) {
    final pages = extractPagesData(conversionResult);
    final validPages = filterValidPages(pages);

    return validPages.map((page) {
      return {
        'pageNumber': page['pageNumber'] ?? 0,
        'imageUrl': page['imageUrl'] ?? '',
        'width': page['width'],
        'height': page['height'],
        'cloudinaryId': page['cloudinaryId'],
      };
    }).toList();
  }

  /// Get conversion progress (for UI feedback)
  static double getConversionProgress(Map<String, dynamic> result) {
    if (!result.containsKey('pages')) return 0.0;
    
    final pages = result['pages'] as List;
    final totalPages = result['totalPages'] ?? pages.length;
    
    if (totalPages == 0) return 0.0;
    
    final loadedPages = pages.where((page) => isPageValid(page)).length;
    return loadedPages / totalPages;
  }

  /// Create error page data
  static Map<String, dynamic> createErrorPage(int pageNumber, String error) {
    return {
      'pageNumber': pageNumber,
      'imageUrl': '',
      'error': error,
      'width': null,
      'height': null,
      'cloudinaryId': null,
    };
  }
}
