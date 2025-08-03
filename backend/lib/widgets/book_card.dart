import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/book_data.dart';
import '../services/cloudinary_service.dart';

class BookCard extends StatelessWidget {
  final BookData book;
  final Duration delay;
  final bool isSelected;
  final VoidCallback? onTap;

  const BookCard({
    super.key,
    required this.book,
    this.delay = Duration.zero,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.3 : 0.1),
              blurRadius: isSelected ? 15 : 10,
              spreadRadius: isSelected ? 3 : 2,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBookImage(),
            const SizedBox(height: 12),
            Text(
              book.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  book.rating.toString(),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookImage() {
    final imageUrl = book.image;
    final optimizedUrl = imageUrl.contains('cloudinary.com')
        ? CloudinaryService.getOptimizedUrl(
            imageUrl,
            width: 300,
            height: 400,
            quality: 'auto',
          )
        : imageUrl;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: CachedNetworkImage(
          imageUrl: optimizedUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFF4A90E2).withOpacity(0.3),
            child: const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF4A90E2),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) {
            return Container(
              color: const Color(0xFF4A90E2),
              child: const Center(
                child: Icon(
                  Icons.book,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}




