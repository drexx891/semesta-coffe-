import 'dart:convert';
import 'package:flutter/material.dart';

class Base64ImageHelper {
  /// Builds an image from a base64 string. Returns a placeholder if invalid.
  static Widget buildImage(String? base64String, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
  }) {
    if (base64String == null || base64String.isEmpty) {
      return placeholder ?? _defaultPlaceholder(width, height);
    }

    try {
      // Remove data URI prefix if exists (e.g. data:image/png;base64,)
      String cleanBase64 = base64String;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      final bytes = base64Decode(cleanBase64);
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return placeholder ?? _defaultPlaceholder(width, height);
        },
      );
    } catch (e) {
      return placeholder ?? _defaultPlaceholder(width, height);
    }
  }

  static Widget _defaultPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: Center(
        child: Icon(
          Icons.local_cafe_rounded,
          color: Colors.grey.shade400,
          size: (width != null && width < 50) ? 24 : 40,
        ),
      ),
    );
  }
}
