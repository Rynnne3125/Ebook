import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flipbook_model.dart';
import '../models/teaching_script_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Check if sample data already exists
  Future<bool> _sampleDataExists() async {
    try {
      final snapshot = await _firestore
          .collection('books')
          .where('title', isEqualTo: 'Bài 2: Chất và hỗn hợp')
          .limit(1)
          .get();
      
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking sample data: $e');
      return false;
    }
  }

  // Add sample chemistry books data (only if not exists)
  Future<void> addSampleChemistryBooks() async {
    try {
      // Check if sample data already exists
      if (await _sampleDataExists()) {
        print('Sample chemistry books already exist, skipping...');
        return;
      }

      print('Adding sample chemistry books...');

      // Bài 2: Chất và hỗn hợp
      await _firestore.collection('books').add({
        'title': 'Bài 2: Chất và hỗn hợp',
        'description': 'Tìm hiểu về khái niệm chất và hỗn hợp, phân biệt các loại hỗn hợp và phương pháp tách chúng trong chương trình Hóa học lớp 8.',
        'heyzineUrl': 'https://heyzine.com/flip-book/e71e41dc46.html',
        'coverImageUrl': 'https://res.cloudinary.com/demo/image/upload/v1/chemistry/chat-hon-hop.jpg',
        'tags': ['Hóa học', 'Lớp 8', 'Chất', 'Hỗn hợp'],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 1200,
        'bookmarkCount': 856,
        'isPublished': true,
        'subject': 'Hóa học',
        'grade': '8',
        'chapter': 2,
        'rating': 4.8,
      });

      // Add other books...
      
      print('Sample chemistry books added successfully!');
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        print('Firestore permission denied. Please check Security Rules.');
        print('Using local fallback data...');
        // Don't throw error, just log it
        return;
      }
      print('Error adding sample books: $e');
    }
  }

  // Add pages for a specific book
  Future<void> addBookPages(String bookId, List<Map<String, dynamic>> pagesData) async {
    try {
      final batch = _firestore.batch();
      
      for (int i = 0; i < pagesData.length; i++) {
        final pageRef = _firestore
            .collection('books')
            .doc(bookId)
            .collection('pages')
            .doc();
        
        batch.set(pageRef, {
          ...pagesData[i],
          'pageNumber': i + 1,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      
      await batch.commit();
      print('Pages added successfully for book: $bookId');
    } catch (e) {
      print('Error adding pages: $e');
    }
  }

  // Get books by subject and grade
  Stream<List<FlipBookModel>> getBooksBySubjectAndGrade(String subject, String grade) {
    return _firestore
        .collection('books')
        .where('subject', isEqualTo: subject)
        .where('grade', isEqualTo: grade)
        .where('isPublished', isEqualTo: true)
        .orderBy('chapter')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlipBookModel.fromFirestore(doc))
            .toList());
  }

  // Get featured books (all books, newest first)
  Stream<List<FlipBookModel>> getFeaturedBooks({int limit = 10}) {
    try {
      return _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
            print('📚 Found ${snapshot.docs.length} books in Firestore:');
            for (var doc in snapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final pages = data['pages'] as List?;
              print('   📖 ${doc.id}: ${data['title']} (${pages?.length ?? 0} pages)');
              if (doc.id == 'f60f20ba-e6fd-45af-b804-fa294d58fc55') {
                print('   🎯 FOUND TARGET BOOK!');
              }
            }
            return snapshot.docs
                .map((doc) => FlipBookModel.fromFirestore(doc))
                .toList();
          });
    } catch (e) {
      print('Error getting featured books: $e');
      // Return local fallback data
      return Stream.value(_getLocalFallbackBooks());
    }
  }

  // Local fallback data
  List<FlipBookModel> _getLocalFallbackBooks() {
    return [
      FlipBookModel(
        id: 'local_1',
        title: 'Bài 2: Chất và hỗn hợp',
        description: 'Tìm hiểu về khái niệm chất và hỗn hợp, phân biệt các loại hỗn hợp và phương pháp tách chúng trong chương trình Hóa học lớp 8.',
        heyzineUrl: 'https://heyzine.com/flip-book/e71e41dc46.html',
        coverImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/chemistry/chat-hon-hop.jpg',
        tags: ['Hóa học', 'Lớp 8', 'Chất', 'Hỗn hợp'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 1200,
        bookmarkCount: 856,
        isPublished: true,
        subject: 'Hóa học',
        grade: '8',
        chapter: 2,
        rating: 4.8,
        pages: _getSamplePages(),
      ),
      FlipBookModel(
        id: 'local_2',
        title: 'Bài 3: Nguyên tử',
        description: 'Khám phá cấu trúc nguyên tử, các hạt cơ bản và sự sắp xếp electron trong chương trình Hóa học lớp 8.',
        heyzineUrl: 'https://heyzine.com/flip-book/a82f31bc47.html',
        coverImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/chemistry/nguyen-tu.jpg',
        tags: ['Hóa học', 'Lớp 8', 'Nguyên tử', 'Electron'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 980,
        bookmarkCount: 642,
        isPublished: true,
        subject: 'Hóa học',
        grade: '8',
        chapter: 3,
        rating: 4.9,
        pages: _getSamplePages(),
      ),
      FlipBookModel(
        id: 'local_3',
        title: 'Bài 4: Nguyên tố hóa học',
        description: 'Học về nguyên tố hóa học, bảng tuần hoàn và tính chất của các nguyên tố trong chương trình Hóa học lớp 8.',
        heyzineUrl: 'https://heyzine.com/flip-book/b93g42ed58.html',
        coverImageUrl: 'https://res.cloudinary.com/demo/image/upload/v1/chemistry/nguyen-to-hoa-hoc.jpg',
        tags: ['Hóa học', 'Lớp 8', 'Nguyên tố', 'Bảng tuần hoàn'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        viewCount: 1500,
        bookmarkCount: 923,
        isPublished: true,
        subject: 'Hóa học',
        grade: '8',
        chapter: 4,
        rating: 4.7,
        pages: _getSamplePages(),
      ),
    ];
  }

  List<FlipBookPageModel> _getSamplePages() {
    return [
      FlipBookPageModel(
        id: 'page_1',
        pageNumber: 1,
        title: 'Giới thiệu',
        content: 'Chào mừng bạn đến với bài học hóa học. Trong bài này chúng ta sẽ tìm hiểu về các khái niệm cơ bản.',
        isCover: true,
      ),
      FlipBookPageModel(
        id: 'page_2',
        pageNumber: 2,
        title: 'Nội dung chính',
        content: 'Đây là nội dung chính của bài học. Chúng ta sẽ đi sâu vào các khái niệm quan trọng và ứng dụng thực tế.',
        isCover: false,
      ),
    ];
  }

  // Search books
  Stream<List<FlipBookModel>> searchBooks(String query) {
    return _firestore
        .collection('books')
        .where('isPublished', isEqualTo: true)
        .orderBy('title')
        .startAt([query])
        .endAt([query + '\uf8ff'])
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FlipBookModel.fromFirestore(doc))
            .toList());
  }

  // Get all published books with better error handling
  Stream<List<FlipBookModel>> getBooks() {
    print('Getting published books from Firestore...');
    return _firestore
        .collection('books')
        .where('isPublished', isEqualTo: true)
        .snapshots()
        .handleError((error) {
          print('Firestore error: $error');
        })
        .map((snapshot) {
          print('Firestore snapshot: ${snapshot.docs.length} documents');
          return snapshot.docs
              .map((doc) => FlipBookModel.fromFirestore(doc))
              .toList();
        });
  }

  // Get book by ID with pages
  Future<FlipBookModel?> getBookWithPages(String bookId) async {
    try {
      final bookDoc = await _firestore.collection('books').doc(bookId).get();
      if (!bookDoc.exists) return null;

      final pagesSnapshot = await _firestore
          .collection('books')
          .doc(bookId)
          .collection('pages')
          .orderBy('pageNumber')
          .get();

      final book = FlipBookModel.fromFirestore(bookDoc);
      book.pages = pagesSnapshot.docs
          .map((doc) => FlipBookPageModel.fromFirestore(doc))
          .toList();

      return book;
    } catch (e) {
      print('Error getting book: $e');
      return null;
    }
  }

  // Save book with Heyzine integration
  Future<String?> saveBook({
    required String title,
    required String description,
    required String heyzineUrl,
    String? coverImageUrl,
    List<String>? tags,
    String? subject,
    String? grade,
    int? chapter,
    double? rating,
  }) async {
    try {
      final docRef = await _firestore.collection('books').add({
        'title': title,
        'description': description,
        'heyzineUrl': heyzineUrl,
        'coverImageUrl': coverImageUrl,
        'tags': tags ?? [],
        'subject': subject,
        'grade': grade,
        'chapter': chapter,
        'rating': rating ?? 0.0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'bookmarkCount': 0,
        'isPublished': true,
      });

      return docRef.id;
    } catch (e) {
      print('Error saving book: $e');
      return null;
    }
  }

  // Save book from backend response with teaching scripts
  Future<String?> saveBookFromBackend(Map<String, dynamic> backendResponse) async {
    try {
      final bookData = {
        'title': backendResponse['title'] ?? '',
        'author': backendResponse['author'] ?? '',
        'description': backendResponse['description'] ?? '',
        'subject': backendResponse['subject'] ?? '',
        'grade': backendResponse['grade'] ?? '8',
        'chapter': backendResponse['chapter'] ?? 1,
        'turnJSPages': backendResponse['turnjs_pages'] ?? [],
        'coverImageUrl': backendResponse['turnjs_pages'] != null &&
                        (backendResponse['turnjs_pages'] as List).isNotEmpty
                        ? backendResponse['turnjs_pages'][0]['image_url'] ?? ''
                        : '',
        'tags': List<String>.from(backendResponse['tags'] ?? ['Turn.js']),
        'rating': 0.0,
        'viewCount': 0,
        'bookmarkCount': 0,
        'isPublished': true,
        'pages': backendResponse['pages'] ?? [],
        'total_pages': backendResponse['total_pages'] ?? 0,
        'pdf_url': backendResponse['pdf_url'] ?? '',
        'created_at': backendResponse['created_at'] ?? DateTime.now().toIso8601String(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('books').add(bookData);
      print('✅ Book saved to Firestore with ID: ${docRef.id}');
      return docRef.id;

    } catch (e) {
      print('Error saving book from backend: $e');
      return null;
    }
  }

  // Update view count
  Future<void> incrementViewCount(String bookId) async {
    await _firestore.collection('books').doc(bookId).update({
      'viewCount': FieldValue.increment(1),
    });
  }

  // Bookmark functionality
  Future<void> toggleBookmark(String userId, String bookId) async {
    final bookmarkRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookId);

    final bookmarkDoc = await bookmarkRef.get();
    
    if (bookmarkDoc.exists) {
      await bookmarkRef.delete();
      await _firestore.collection('books').doc(bookId).update({
        'bookmarkCount': FieldValue.increment(-1),
      });
    } else {
      await bookmarkRef.set({
        'bookId': bookId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('books').doc(bookId).update({
        'bookmarkCount': FieldValue.increment(1),
      });
    }
  }

  Future<void> addBookWithHeyzineUrl(String title, String description, String heyzineUrl) async {
    try {
      await _firestore.collection('books').add({
        'title': title,
        'description': description,
        'heyzineUrl': heyzineUrl, // Link share từ Heyzine
        'createdAt': FieldValue.serverTimestamp(),
        'viewCount': 0,
        'isPublished': true,
      });
    } catch (e) {
      print('Error adding book: $e');
    }
  }

  // Save book with Turn.js data
  Future<String?> saveBookWithTurnJS({
    required String title,
    required String description,
    required String pdfUrl,
    required List<Map<String, dynamic>> turnJSPages,
    String? coverImageUrl,
    List<String> tags = const [],
    String? subject,
    String? grade,
    int? chapter,
    double rating = 0.0,
  }) async {
    try {
      final bookData = {
        'title': title,
        'description': description,
        'pdfUrl': pdfUrl,
        'turnJSPages': turnJSPages,
        'coverImageUrl': coverImageUrl ?? (turnJSPages.isNotEmpty ? turnJSPages[0]['image_url'] : ''),
        'tags': tags,
        'subject': subject,
        'grade': grade,
        'chapter': chapter,
        'rating': rating,
        'viewCount': 0,
        'bookmarkCount': 0,
        'isPublished': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('books').add(bookData);
      print('✅ Book saved with Turn.js data: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('Error saving book with Turn.js: $e');
      return null;
    }
  }

  // Get EBook with teaching scripts
  Future<EBook?> getEBookWithScripts(String bookId) async {
    try {
      print('🔍 Searching for book with ID: $bookId');

      final doc = await _firestore.collection('books').doc(bookId).get();

      if (!doc.exists) {
        print('❌ Book not found: $bookId');
        return null;
      }

      final data = doc.data()!;
      print('📄 Found book with ${data['pages'] != null ? (data['pages'] as List).length : 0} pages');

      // Parse pages with teaching scripts
      List<BookPage> pages = [];
      if (data['pages'] != null) {
        final pagesData = List<Map<String, dynamic>>.from(data['pages']);

        for (var pageData in pagesData) {
          TeachingScript? teachingScript;

          if (pageData['teaching_script'] != null) {
            teachingScript = TeachingScript.fromJson(
              Map<String, dynamic>.from(pageData['teaching_script'])
            );
          }

          pages.add(BookPage(
            pageNumber: pageData['page_number'] ?? 1,
            content: pageData['content'] ?? '',
            teachingScript: teachingScript,
          ));
        }

        // Sort pages by pageNumber to ensure correct order
        pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
        print('📚 Sorted ${pages.length} pages by pageNumber');
      }

      return EBook(
        id: doc.id,
        title: data['title'] ?? '',
        author: data['author'] ?? '',
        subject: data['subject'] ?? '',
        pdfUrl: data['pdf_url'] ?? '',
        flipbookUrl: data['heyzineUrl'] ?? '',
        pages: pages,
        totalPages: data['total_pages'] ?? pages.length,
        createdAt: data['created_at'] != null
            ? DateTime.parse(data['created_at'])
            : DateTime.now(),
        heyzineData: data['heyzine_data'],
      );

    } catch (e) {
      print('Error getting EBook with scripts: $e');
      return null;
    }
  }
}


