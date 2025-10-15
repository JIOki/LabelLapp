import 'dart:ui';

import 'package:flutter/foundation.dart';

@immutable
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;
  final String label;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.label,
  });

  double get width => right - left;
  double get height => bottom - top;

  factory BoundingBox.fromRect(Rect rect, String label) {
    return BoundingBox(
      left: rect.left,
      top: rect.top,
      right: rect.right,
      bottom: rect.bottom,
      label: label,
    );
  }

  Rect toRect() {
    return Rect.fromLTRB(left, top, right, bottom);
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BoundingBox &&
          runtimeType == other.runtimeType &&
          left == other.left &&
          top == other.top &&
          right == other.right &&
          bottom == other.bottom &&
          label == other.label;

  @override
  int get hashCode =>
      left.hashCode ^
      top.hashCode ^
      right.hashCode ^
      bottom.hashCode ^
      label.hashCode;
}
