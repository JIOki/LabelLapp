import 'package:flutter/material.dart';
import '../ui/screens/home/home_screen.dart';
import '../ui/screens/labeling/labeling_screen.dart';

class AppRoutes {
  static Map<String, WidgetBuilder> routes = {
    '/': (context) => const HomeScreen(),
    '/label': (context) => const LabelingScreen(),
  };
}
