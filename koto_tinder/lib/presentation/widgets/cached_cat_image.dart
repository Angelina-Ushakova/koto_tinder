// lib/presentation/widgets/cached_cat_image.dart

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:koto_tinder/data/datasources/enhanced_image_cache_service.dart';
import 'package:koto_tinder/di/service_locator.dart';

class CachedCatImage extends StatefulWidget {
  const CachedCatImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.memCacheWidth,
    this.memCacheHeight,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  State<CachedCatImage> createState() => _CachedCatImageState();
}

class _CachedCatImageState extends State<CachedCatImage> {
  final _cache = serviceLocator<EnhancedImageCacheService>();
  String? _localPath;
  bool _checked = false;

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    _localPath = await _cache.getCachedImagePath(widget.imageUrl);
    if (mounted) setState(() => _checked = true);
  }

  Widget _ph() =>
      widget.placeholder ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );

  Widget _err() =>
      widget.errorWidget ??
      Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            SizedBox(height: 8),
            Text('Фото недоступно\nбез интернета', textAlign: TextAlign.center),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (!_checked) return _ph();

    // офлайн
    if (_localPath case final p? when File(p).existsSync()) {
      return Image.file(
        File(p),
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
        errorBuilder: (_, __, ___) => _netImage(),
      );
    }

    return _netImage();
  }

  Widget _netImage() {
    return CachedNetworkImage(
      imageUrl: widget.imageUrl,
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      memCacheWidth: widget.memCacheWidth,
      memCacheHeight: widget.memCacheHeight,
      placeholder: (_, __) => _ph(),
      errorWidget: (_, __, ___) {
        _cache.cacheImage(widget.imageUrl);
        return _err();
      },
      imageBuilder: (_, provider) {
        _cache.cacheImage(widget.imageUrl);
        return Image(
          image: provider,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
        );
      },
    );
  }
}
