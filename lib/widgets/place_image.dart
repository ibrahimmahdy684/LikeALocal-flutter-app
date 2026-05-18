import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PlaceImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;

  const PlaceImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.startsWith('data:')) {
      final base64Str = imageUrl.split(',').last;
      final Uint8List bytes = base64Decode(base64Str);
      return Image.memory(
        bytes,
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorWidget: (_, __, ___) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, color: Colors.grey),
    );
  }
}
