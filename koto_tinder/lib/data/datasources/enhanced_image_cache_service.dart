import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class EnhancedImageCacheService {
  static final _instance = EnhancedImageCacheService._internal();
  factory EnhancedImageCacheService() => _instance;
  EnhancedImageCacheService._internal();

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  static const _maxCacheFiles = 200;
  Directory? _cacheDir;

  Future<Directory> get _dir async {
    if (_cacheDir != null) return _cacheDir!;
    final root = await getApplicationDocumentsDirectory();
    _cacheDir = Directory(p.join(root.path, 'enhanced_cat_cache'));
    if (!await _cacheDir!.exists()) await _cacheDir!.create(recursive: true);
    return _cacheDir!;
  }

  String _hash(String input) => md5.convert(utf8.encode(input)).toString();

  /// Нормализуем ссылку: отбрасываем query/fragment, чтобы один кот = один файл
  String _normalizeUrl(String url) {
    final uri = Uri.parse(url);
    return '${uri.scheme}://${uri.host}${uri.path}';
  }

  Future<String> _filePath(String url) async {
    final dir = await _dir;
    final name = '${_hash(_normalizeUrl(url))}.jpg';
    return p.join(dir.path, name);
  }

  /// Файл уже в кэше и не битый (>1KB)?
  Future<bool> isImageCached(String url) async {
    final file = File(await _filePath(url));
    return file.existsSync() && await file.length() > 1024;
  }

  /// Путь к файлу если есть, иначе null
  Future<String?> getCachedImagePath(String url) async {
    return await isImageCached(url) ? await _filePath(url) : null;
  }

  /// Кэшируем картинку (если нужно) и возвращаем путь (или null)
  Future<String?> cacheImage(String url) async {
    try {
      final file = File(await _filePath(url));
      if (file.existsSync() && await file.length() > 1024) {
        await file.setLastModified(DateTime.now());
        return file.path;
      }
      final resp = await _dio.get(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (resp.statusCode == 200 && resp.data != null) {
        await file.writeAsBytes(resp.data as Uint8List);
        if (await file.length() > 1024) {
          _manageCacheSize();
          return file.path;
        }
      }
    } catch (_) {
      /* ignore */
    }
    return null;
  }

  /// Предзагрузка (асинхронно, без ожидания)
  void preloadImage(String url) {
    cacheImage(url);
  }

  Future<void> _manageCacheSize() async {
    try {
      final files =
          (await (await _dir).list().toList()).whereType<File>().toList();
      if (files.length <= _maxCacheFiles) return;
      files.sort(
        (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
      );
      for (final f in files.take(files.length - _maxCacheFiles)) {
        await f.delete();
      }
    } catch (_) {
      /* ignore */
    }
  }
}
