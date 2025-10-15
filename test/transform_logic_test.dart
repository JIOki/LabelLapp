import 'package:flutter_test/flutter_test.dart';
import 'package:labellab/ui/screens/annotation/transform_logic.dart';
import 'dart:ui';

import 'package:vector_math/vector_math_64.dart';

void main() {
  group('calculateImageTransform', () {
    test('should scale to fit width when image is wider than canvas', () {
      const imageSize = Size(200, 100);
      const canvasSize = Size(100, 100);

      final transform = calculateImageTransform(imageSize, canvasSize);

      final expectedScale = 0.5;
      final expectedTranslation = Vector3(0, 25, 0);

      final actualScale = Vector3.zero();
      final actualTranslation = Vector3.zero();
      final actualRotation = Quaternion.identity();
      transform.decompose(actualTranslation, actualRotation, actualScale);

      expect(actualScale, closeToVector(Vector3(expectedScale, expectedScale, expectedScale)));
      expect(actualTranslation, closeToVector(expectedTranslation));
    });

    test('should scale to fit height when image is taller than canvas', () {
      const imageSize = Size(100, 200);
      const canvasSize = Size(100, 100);

      final transform = calculateImageTransform(imageSize, canvasSize);

      final expectedScale = 0.5;
      final expectedTranslation = Vector3(25, 0, 0);
      
      final actualScale = Vector3.zero();
      final actualTranslation = Vector3.zero();
      final actualRotation = Quaternion.identity();
      transform.decompose(actualTranslation, actualRotation, actualScale);

      expect(actualScale, closeToVector(Vector3(expectedScale, expectedScale, expectedScale)));
      expect(actualTranslation, closeToVector(expectedTranslation));
    });
  });
}

Matcher closeToVector(Vector3 expected, {double epsilon = 0.001}) {
  return predicate((v) {
    if (v is! Vector3) return false;
    return (v - expected).length < epsilon;
  }, 'is close to $expected');
}
