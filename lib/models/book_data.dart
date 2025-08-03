class BookData {
  final String title;
  final String image;
  final double rating;
  final String? description;

  BookData({
    required this.title,
    required this.image,
    required this.rating,
    this.description,
  });
}
