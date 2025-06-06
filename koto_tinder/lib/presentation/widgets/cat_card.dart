import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:koto_tinder/domain/entities/cat.dart';
import 'package:koto_tinder/presentation/widgets/cached_cat_image.dart';

class CatCard extends StatelessWidget {
  final Cat cat;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final bool showLikedDate;

  const CatCard({
    super.key,
    required this.cat,
    required this.onTap,
    this.onRemove,
    this.showLikedDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Изображение котика
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.5,
                    child: CachedCatImage(
                      imageUrl: cat.url,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.error, color: Colors.red, size: 40),
                        ),
                      ),
                    ),
                  ),
                ),
                // Кнопка удаления, если она предоставлена
                if (onRemove != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withAlpha(180),
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: onRemove,
                        customBorder: const CircleBorder(),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.close,
                            color: Colors.red[700],
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Информация о котике
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Название породы
                  Text(
                    cat.breeds != null && cat.breeds!.isNotEmpty
                        ? cat.breeds![0].name
                        : 'Неизвестная порода',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  // Дата лайка, если нужно отображать
                  if (showLikedDate && cat.likedAt != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Лайк: ${DateFormat('dd.MM.yyyy HH:mm').format(cat.likedAt!)}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
