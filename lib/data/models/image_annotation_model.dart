import 'bbox_model.dart';

class ImageAnnotation {
  final String imagePath;
  final List<BBox> bboxes;

  ImageAnnotation({required this.imagePath, required this.bboxes});
}
