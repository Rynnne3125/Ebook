import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models/teaching_script_model.dart';
import 'firestore_service.dart';

class BackendApiService {
  static const String baseUrl = 'http://localhost:5001';
  
  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      print('Backend API health check failed: $e');
      return false;
    }
  }

  // Upload PDF and process from File (for mobile/desktop)
  static Future<EBook?> uploadPdf({
    required File pdfFile,
    required String title,
    required String author,
    String subject = 'Chemistry',
  }) async {
    try {
      print('📤 Uploading PDF to backend...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf'),
      );

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', pdfFile.path),
      );

      // Add form data
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['subject'] = subject;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ PDF uploaded and processed successfully');
        return EBook.fromJson(jsonData);
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading PDF: $e');
      return null;
    }
  }

  // Upload PDF and process from bytes (for web)
  static Future<EBook?> uploadPdfFromBytes({
    required Uint8List pdfBytes,
    required String fileName,
    required String title,
    required String author,
    String subject = 'Chemistry',
  }) async {
    try {
      print('📤 Uploading PDF to backend from bytes...');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf'),
      );

      // Add file from bytes
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          pdfBytes,
          filename: fileName,
        ),
      );

      // Add form data
      request.fields['title'] = title;
      request.fields['author'] = author;
      request.fields['subject'] = subject;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        print('✅ PDF uploaded and processed successfully');

        // Save to Firestore
        final firestoreService = FirestoreService();
        final firestoreId = await firestoreService.saveBookFromBackend(jsonData);

        if (firestoreId != null) {
          print('✅ Book saved to Firestore with ID: $firestoreId');
          // Add Firestore ID to the response
          jsonData['firestore_id'] = firestoreId;
        }

        return EBook.fromJson(jsonData);
      } else {
        print('❌ Upload failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('❌ Error uploading PDF: $e');
      return null;
    }
  }

  // Get all books
  static Future<List<EBook>> getBooks() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final List<dynamic> booksJson = jsonData['books'];
        return booksJson.map((book) => EBook.fromJson(book)).toList();
      } else {
        print('Failed to fetch books: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error fetching books: $e');
      return [];
    }
  }

  // Get specific book
  static Future<EBook?> getBook(String bookId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/books/$bookId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return EBook.fromJson(jsonData);
      } else {
        print('Failed to fetch book: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error fetching book: $e');
      return null;
    }
  }

  // Save book to Firestore (after processing)
  static Future<bool> saveBookToFirestore(EBook book) async {
    try {
      print('📝 Saving book to Firestore: ${book.title}');

      // Import FirestoreService
      final firestoreService = FirestoreService();

      // Save book with proper format matching sample books
      final bookId = await firestoreService.saveBook(
        title: book.title,
        description: book.description ?? 'Sách ${book.subject} - ${book.title}. Được tạo tự động từ PDF với AI teaching scripts.',
        heyzineUrl: book.heyzineUrl ?? book.pdfUrl,
        coverImageUrl: book.coverImageUrl,
        tags: [book.subject, 'AI Generated', 'Interactive'],
        subject: book.subject,
        grade: '8',  // Default grade
        chapter: 1,  // Default chapter
        rating: 0.0,
      );

      if (bookId != null) {
        // Save pages with teaching scripts
        final pagesData = book.pages.map((page) => {
          'content': page.content,
          'teachingScript': page.teachingScript?.toJson(),
          'keyPoints': page.teachingScript?.keyConcepts ?? [],
          'questions': page.teachingScript?.questions ?? [],
          'examples': page.teachingScript?.examples ?? [],
          'duration': page.teachingScript?.durationMinutes ?? 2,
        }).toList();

        await firestoreService.addBookPages(bookId, pagesData);
        print('✅ Book and pages saved to Firestore successfully');
        return true;
      }

      return false;
    } catch (e) {
      print('Error saving book to Firestore: $e');
      return false;
    }
  }
}
