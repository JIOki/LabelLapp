import 'dart:ui';
import 'package:flutter/foundation.dart';

@immutable
class BoundingBox {
  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.label,
  });

  final double left;
  final double top;
  final double right;
  final double bottom;
  final String label;

  // Convierte este BoundingBox a un objeto Rect de Flutter
  Rect toRect() => Rect.fromLTRB(left, top, right, bottom);

  // Factory para crear un BoundingBox a partir de un Rect y una etiqueta
  factory BoundingBox.fromRect(Rect rect, String label) {
    return BoundingBox(
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
      label: label,
    );
  }

  BoundingBox copyWith({
    double? left,
    double? top,
    double? right,
    double? bottom,
    String? label,
  }) {
    return BoundingBox(
      left: left ?? this.left,
      top: top ?? this.top,
      right: right ?? this.right,
      bottom: bottom ?? this.bottom,
      label: label ?? this.label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
      'label': label,
    };
  }

  factory BoundingBox.fromJson(Map<String, dynamic> json) {
    return BoundingBox(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      right: (json['right'] as num).toDouble(),
      bottom: (json['bottom'] as num).toDouble(),
      label: json['label'] as String,
    );
  }
}
