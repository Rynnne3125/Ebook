import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../services/backend_api_service.dart';
import '../models/teaching_script_model.dart';
import '../utils/app_colors.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../utils/responsive_utils.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _subjectController = TextEditingController(text: 'Chemistry');
  
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  File? _selectedFile;
  bool _isUploading = false;
  String _uploadStatus = '';
  EBook? _processedBook;

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
        withData: kIsWeb, // Load file data for web platform
      );

      if (result != null && result.files.single != null) {
        final file = result.files.single;
        setState(() {
          _selectedFileName = file.name;
          _uploadStatus = 'File selected: ${file.name}';

          if (kIsWeb) {
            // For web platform, use bytes
            _selectedFileBytes = file.bytes;
            _selectedFile = null;
          } else {
            // For mobile/desktop platform, use file path
            if (file.path != null) {
              _selectedFile = File(file.path!);
              _selectedFileBytes = null;
            }
          }
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error selecting file: $e';
      });
    }
  }

  Future<void> _uploadAndProcess() async {
    if (!_formKey.currentState!.validate() ||
        (_selectedFile == null && _selectedFileBytes == null)) {
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading and processing PDF...';
      _processedBook = null;
    });

    try {
      // Check backend health first
      final isHealthy = await BackendApiService.checkHealth();
      if (!isHealthy) {
        setState(() {
          _uploadStatus = 'Backend API is not available. Please start the backend server.';
          _isUploading = false;
        });
        return;
      }

      // Upload and process PDF
      EBook? book;
      if (kIsWeb && _selectedFileBytes != null) {
        // For web platform, use bytes
        book = await BackendApiService.uploadPdfFromBytes(
          pdfBytes: _selectedFileBytes!,
          fileName: _selectedFileName!,
          title: _titleController.text,
          author: _authorController.text,
          subject: _subjectController.text,
        );
      } else if (_selectedFile != null) {
        // For mobile/desktop platform, use file
        book = await BackendApiService.uploadPdf(
          pdfFile: _selectedFile!,
          title: _titleController.text,
          author: _authorController.text,
          subject: _subjectController.text,
        );
      }

      if (book != null) {
        setState(() {
          _processedBook = book;
          _uploadStatus = 'Successfully processed! Generated ${book?.pages.length} teaching scripts.';
        });

        // Save to Firestore
        await BackendApiService.saveBookToFirestore(book);
        
        // Show success dialog
        _showSuccessDialog(book);
      } else {
        setState(() {
          _uploadStatus = 'Failed to process PDF. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = 'Error: $e';
      });
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog(EBook book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('✅ Success!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Book "${book.title}" has been processed successfully!'),
            const SizedBox(height: 16),
            Text('📚 Total pages: ${book.totalPages}'),
            Text('🤖 AI scripts generated: ${book.pages.length}'),
            Text('📖 Flipbook URL: ${book.flipbookUrl.isNotEmpty ? "Generated" : "Failed"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Navigate to book reader
              Navigator.pushNamed(context, '/flipbook-reader', arguments: {
                'flipbookUrl': book.flipbookUrl,
                'bookTitle': book.title,
                'bookId': book.id,
              });
            },
            child: const Text('View Book'),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _selectedFile = null;
      _selectedFileBytes = null;
      _selectedFileName = null;
      _uploadStatus = '';
      _processedBook = null;
    });
    _titleController.clear();
    _authorController.clear();
    _subjectController.text = 'Chemistry';
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveUtils.isMobile(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Admin Panel - Upload Books'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header
                        const Icon(
                          Icons.cloud_upload,
                          size: 64,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Upload PDF Book',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Upload a PDF file to automatically generate flipbook and AI teaching scripts',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        // Form fields
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Book Title *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.book),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter book title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _authorController,
                          decoration: const InputDecoration(
                            labelText: 'Author *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter author name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _subjectController,
                          decoration: const InputDecoration(
                            labelText: 'Subject',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.science),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // File picker
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                (_selectedFile != null || _selectedFileBytes != null) ? Icons.check_circle : Icons.upload_file,
                                size: 48,
                                color: (_selectedFile != null || _selectedFileBytes != null) ? Colors.green : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                (_selectedFile != null || _selectedFileBytes != null)
                                    ? 'File selected: ${_selectedFileName ?? (_selectedFile?.path.split('/').last ?? 'Unknown')}'
                                    : 'No file selected',
                                style: TextStyle(
                                  color: (_selectedFile != null || _selectedFileBytes != null) ? Colors.green : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _isUploading ? null : _pickFile,
                                icon: const Icon(Icons.folder_open),
                                label: const Text('Select PDF File'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Upload button
                        ElevatedButton(
                          onPressed: (_isUploading || (_selectedFile == null && _selectedFileBytes == null)) ? null : _uploadAndProcess,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isUploading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Processing...'),
                                  ],
                                )
                              : const Text(
                                  'Upload & Process PDF',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                        
                        // Status
                        if (_uploadStatus.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _uploadStatus.contains('Error') || _uploadStatus.contains('Failed')
                                  ? Colors.red[50]
                                  : _uploadStatus.contains('Success')
                                      ? Colors.green[50]
                                      : Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _uploadStatus.contains('Error') || _uploadStatus.contains('Failed')
                                    ? Colors.red[300]!
                                    : _uploadStatus.contains('Success')
                                        ? Colors.green[300]!
                                        : Colors.blue[300]!,
                              ),
                            ),
                            child: Text(
                              _uploadStatus,
                              style: TextStyle(
                                color: _uploadStatus.contains('Error') || _uploadStatus.contains('Failed')
                                    ? Colors.red[700]
                                    : _uploadStatus.contains('Success')
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                              ),
                            ),
                          ),
                        ],

                        // Processed book info
                        if (_processedBook != null) ...[
                          const SizedBox(height: 24),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green[300]!),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '📚 Processed Book Details',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text('Title: ${_processedBook!.title}'),
                                Text('Author: ${_processedBook!.author}'),
                                Text('Total Pages: ${_processedBook!.totalPages}'),
                                Text('AI Scripts: ${_processedBook!.pages.length}'),
                                if (_processedBook!.flipbookUrl.isNotEmpty)
                                  Text('Flipbook: ✅ Generated'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
