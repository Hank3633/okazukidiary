import 'package:flutter/material.dart';

class CategoryItem {
  const CategoryItem(this.imagePath, this.label, this.color, {this.customId});
  final String? customId;
  String get id => customId ?? imagePath;
  bool get isCustom => customId != null;
  Map<String, dynamic> toJson() => {
    'id': customId,
    'image': imagePath,
    'label': label,
    'color': color.toARGB32(),
  };
  factory CategoryItem.fromJson(Map<String, dynamic> json) => CategoryItem(
    json['image'] as String,
    json['label'] as String,
    Color(json['color'] as int),
    customId: json['id'] as String?,
  );
  final String imagePath;
  final String label;
  final Color color;
}
