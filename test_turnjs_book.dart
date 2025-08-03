import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  // Initialize Firestore
  final firestore = FirebaseFirestore.instance;
  
  // Test Turn.js data from curl response
  final turnJSPages = [
    {
      "height": 1553,
      "image_url": "https://res.cloudinary.com/ddjrbkhpx/image/upload/v1754197755/ebook_pages/turnjs/1fdaee50-a751-4ce2-8909-d314ee72507c/page_1.png",
      "page_number": 1,
      "public_id": "ebook_pages/turnjs/1fdaee50-a751-4ce2-8909-d314ee72507c/page_1",
      "width": 1200
    }
  ];
  
  // Create test book
  final bookData = {
    'title': 'Test Turn.js Book',
    'description': 'Test book for Turn.js flipbook reader',
    'pdfUrl': 'https://example.com/test.pdf',
    'turnJSPages': turnJSPages,
    'coverImageUrl': turnJSPages[0]['image_url'],
    'tags': ['Test', 'Turn.js'],
    'subject': 'Test',
    'grade': '8',
    'chapter': 1,
    'rating': 0.0,
    'viewCount': 0,
    'bookmarkCount': 0,
    'isPublished': true,
    'pages': [
      {
        'page_number': 1,
        'content': 'Test page content',
        'teaching_script': 'This is a test page for Turn.js flipbook reader.'
      }
    ],
    'total_pages': 1,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
  
  try {
    final docRef = await firestore.collection('books').add(bookData);
    print('✅ Test book created with ID: ${docRef.id}');
  } catch (e) {
    print('❌ Error creating test book: $e');
  }
}
