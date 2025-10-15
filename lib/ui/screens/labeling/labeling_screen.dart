import 'package:flutter/material.dart';

class LabelingScreen extends StatelessWidget {
  const LabelingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Etiquetado")),
      body: const Center(child: Text("Aquí se etiquetará la imagen")),
    );
  }
}
