import 'dart:io';

import 'package:flutter/material.dart';

import '../models/category_item.dart';

class CategoryIcon extends StatelessWidget {
  const CategoryIcon({super.key, required this.category, this.size = 36});
  final CategoryItem category;
  final double size;
  @override
  Widget build(BuildContext context) {
    final fallback = Icon(Icons.category, size: size, color: category.color);
    return category.imagePath.startsWith('assets/')
        ? Image.asset(
            category.imagePath,
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => fallback,
          )
        : Image.file(
            File(category.imagePath),
            width: size,
            height: size,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => fallback,
          );
  }
}
