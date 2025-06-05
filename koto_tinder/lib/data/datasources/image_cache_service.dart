import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageCacheService {
  static final ImageCacheService _instance = ImageCacheService._internal();
  factory ImageCacheService() => _instance;
  ImageCacheService._internal();

  final Dio _dio = Dio();

  // Получить путь к кэшированному изображению
  Future<String> getCachedImagePath(String imageUrl) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = imageUrl.split('/').last.split('?').first;
    final filePath = path.join(directory.path, 'cached_images', fileName);
    return filePath;
  }

  // Проверить, есть ли изображение в кэше
  Future<bool> isImageCached(String imageUrl) async {
    final filePath = await getCachedImagePath(imageUrl);
    return File(filePath).exists();
  }

  // Загрузить и сохранить изображение
  Future<String> cacheImage(String imageUrl) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(path.join(directory.path, 'cached_images'));

      // Создаем папку если её нет
      if (!await cacheDir.exists()) {
        await cacheDir.create(recursive: true);
      }

      final filePath = await getCachedImagePath(imageUrl);

      // Если файл уже есть, возвращаем путь
      if (await File(filePath).exists()) {
        return filePath;
      }

      // Загружаем изображение
      final response = await _dio.get(
        imageUrl,
        options: Options(responseType: ResponseType.bytes),
      );

      // Сохраняем в файл
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      return filePath;
    } catch (e) {
      throw Exception('Failed to cache image: $e');
    }
  }

  // Получить кэшированное изображение (если есть)
  Future<String?> getCachedImage(String imageUrl) async {
    if (await isImageCached(imageUrl)) {
      return await getCachedImagePath(imageUrl);
    }
    return null;
  }
}
