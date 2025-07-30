import 'package:cloud_firestore/cloud_firestore.dart';

class FlipBookModel {
  final String id;
  final String title;
  final String description;
  final String? heyzineUrl;
  final String? coverImageUrl;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int viewCount;
  final int bookmarkCount;
  final bool isPublished;
  final String? subject;
  final String? grade;
  final int? chapter;
  final double rating;
  List<FlipBookPageModel> pages;

  FlipBookModel({
    required this.id,
    required this.title,
    required this.description,
    this.heyzineUrl,
    this.coverImageUrl,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
    this.viewCount = 0,
    this.bookmarkCount = 0,
    this.isPublished = true,
    this.subject,
    this.grade,
    this.chapter,
    this.rating = 0.0,
    this.pages = const [],
  });

  factory FlipBookModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlipBookModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      heyzineUrl: data['heyzineUrl'],
      coverImageUrl: data['coverImageUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      viewCount: data['viewCount'] ?? 0,
      bookmarkCount: data['bookmarkCount'] ?? 0,
      isPublished: data['isPublished'] ?? true,
      subject: data['subject'],
      grade: data['grade'],
      chapter: data['chapter'],
      rating: (data['rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'heyzineUrl': heyzineUrl,
      'coverImageUrl': coverImageUrl,
      'tags': tags,
      'subject': subject,
      'grade': grade,
      'chapter': chapter,
      'rating': rating,
      'viewCount': viewCount,
      'bookmarkCount': bookmarkCount,
      'isPublished': isPublished,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}

class FlipBookPageModel {
  final String id;
  final String title;
  final String content;
  final int pageNumber;
  final bool isCover;
  final String? imageUrl;
  final String? heyzinePageUrl;
  final Map<String, dynamic>? metadata;

  FlipBookPageModel({
    required this.id,
    required this.title,
    required this.content,
    required this.pageNumber,
    this.isCover = false,
    this.imageUrl,
    this.heyzinePageUrl,
    this.metadata,
  });

  factory FlipBookPageModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FlipBookPageModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      pageNumber: data['pageNumber'] ?? 0,
      isCover: data['isCover'] ?? false,
      imageUrl: data['imageUrl'],
      heyzinePageUrl: data['heyzinePageUrl'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'pageNumber': pageNumber,
      'isCover': isCover,
      'imageUrl': imageUrl,
      'heyzinePageUrl': heyzinePageUrl,
      'metadata': metadata,
    };
  }
}


