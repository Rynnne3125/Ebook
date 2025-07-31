class TeachingScript {
  final String script;
  final List<String> keyConcepts;
  final List<String> examples;
  final List<String> questions;
  final int durationMinutes;
  final DateTime createdAt;

  TeachingScript({
    required this.script,
    required this.keyConcepts,
    required this.examples,
    required this.questions,
    required this.durationMinutes,
    required this.createdAt,
  });

  factory TeachingScript.fromJson(Map<String, dynamic> json) {
    return TeachingScript(
      script: json['script'] ?? '',
      keyConcepts: List<String>.from(json['key_concepts'] ?? []),
      examples: List<String>.from(json['examples'] ?? []),
      questions: List<String>.from(json['questions'] ?? []),
      durationMinutes: json['duration_minutes'] ?? 2,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'script': script,
      'key_concepts': keyConcepts,
      'examples': examples,
      'questions': questions,
      'duration_minutes': durationMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class BookPage {
  final int pageNumber;
  final String content;
  final TeachingScript? teachingScript;

  BookPage({
    required this.pageNumber,
    required this.content,
    this.teachingScript,
  });

  factory BookPage.fromJson(Map<String, dynamic> json) {
    return BookPage(
      pageNumber: json['page_number'] ?? 0,
      content: json['content'] ?? '',
      teachingScript: json['teaching_script'] != null
          ? TeachingScript.fromJson(json['teaching_script'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page_number': pageNumber,
      'content': content,
      'teaching_script': teachingScript?.toJson(),
    };
  }
}

class EBook {
  final String id;
  final String title;
  final String author;
  final String subject;
  final String pdfUrl;
  final String flipbookUrl;
  final List<BookPage> pages;
  final int totalPages;
  final DateTime createdAt;
  final Map<String, dynamic>? heyzineData;
  final String? description;
  final String? heyzineUrl;
  final String? coverImageUrl;

  EBook({
    required this.id,
    required this.title,
    required this.author,
    required this.subject,
    required this.pdfUrl,
    required this.flipbookUrl,
    required this.pages,
    required this.totalPages,
    required this.createdAt,
    this.heyzineData,
    this.description,
    this.heyzineUrl,
    this.coverImageUrl,
  });

  factory EBook.fromJson(Map<String, dynamic> json) {
    return EBook(
      id: json['book_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      author: json['author'] ?? '',
      subject: json['subject'] ?? '',
      pdfUrl: json['pdf_url'] ?? '',
      flipbookUrl: json['flipbook_url'] ?? '',
      pages: (json['pages'] as List<dynamic>?)
          ?.map((page) => BookPage.fromJson(page))
          .toList() ?? [],
      totalPages: json['total_pages'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      heyzineData: json['heyzine_data'],
      description: json['description'],
      heyzineUrl: json['heyzine_url'] ?? json['flipbook_url'],
      coverImageUrl: json['cover_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'subject': subject,
      'pdf_url': pdfUrl,
      'flipbook_url': flipbookUrl,
      'pages': pages.map((page) => page.toJson()).toList(),
      'total_pages': totalPages,
      'created_at': createdAt.toIso8601String(),
      'heyzine_data': heyzineData,
    };
  }
}
