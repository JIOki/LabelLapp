import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

Matrix4 calculateImageTransform(Size imageSize, Size canvasSize) {
  final imageAspectRatio = imageSize.width / imageSize.height;
  final canvasAspectRatio = canvasSize.width / canvasSize.height;

  double scale;
  double dx = 0.0;
  double dy = 0.0;

  if (imageAspectRatio > canvasAspectRatio) {
    scale = canvasSize.width / imageSize.width;
    dy = (canvasSize.height - imageSize.height * scale) / 2;
  } else {
    scale = canvasSize.height / imageSize.height;
    dx = (canvasSize.width - imageSize.width * scale) / 2;
  }

  final translationMatrix = Matrix4.translationValues(dx, dy, 0.0);
  final scaleMatrix = Matrix4.diagonal3Values(scale, scale, 1.0);

  return translationMatrix * scaleMatrix;
}
