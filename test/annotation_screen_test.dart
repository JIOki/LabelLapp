import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_lab/data/models/annotation_model.dart';
import 'package:label_lab/data/models/bounding_box_model.dart';
import 'package:label_lab/data/models/image_model.dart';
import 'package:label_lab/data/models/project_model.dart';
import 'package:label_lab/ui/screens/annotation/annotation_screen.dart';

// A 1x1 transparent PNG
final kTestImageBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

void main() {
  testWidgets('AnnotationScreen renders correctly', (WidgetTester tester) async {
    final project = Project(id: '1', name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(name: 'Test Image', bytes: kTestImageBytes);

    await tester.pumpWidget(MaterialApp(
      home: AnnotationScreen(image: image, project: project),
    ));

    expect(find.text('Test Image'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('Tapping save button pops the navigator', (WidgetTester tester) async {
    final project = Project(id: '1', name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(name: 'Test Image', bytes: kTestImageBytes);

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AnnotationScreen(image: image, project: project),
            ));
          },
          child: const Text('Go to Annotation'),
        ),
      ),
    ));

    // Navigate to the annotation screen
    await tester.tap(find.text('Go to Annotation'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Test Image'), findsOneWidget);

    // Tap the save button
    await tester.tap(find.byIcon(Icons.save));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify we are back on the home screen
    expect(find.text('Test Image'), findsNothing);
    expect(find.text('Go to Annotation'), findsOneWidget);
  });

  testWidgets('Class selector chips are displayed and can be selected', (WidgetTester tester) async {
    final project = Project(id: '1', name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(
      name: 'Test Image',
      bytes: kTestImageBytes,
      annotation: Annotation(
        boxes: const [
          BoundingBox(left: 0, top: 0, right: 10, bottom: 10, label: 'class1'),
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: AnnotationScreen(image: image, project: project),
    ));
    await tester.pumpAndSettle(); 

    // Verify both class chips are displayed
    expect(find.widgetWithText(ChoiceChip, 'class1'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'class2'), findsOneWidget);

    // Verify none are selected initially
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class1')).selected, isFalse);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class2')).selected, isFalse);

    // Tap on the second class
    await tester.tap(find.widgetWithText(ChoiceChip, 'class2'));
    await tester.pumpAndSettle();

    // Verify the second chip is selected and the first is not
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class1')).selected, isFalse);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class2')).selected, isTrue);

     // Tap on the first class
    await tester.tap(find.widgetWithText(ChoiceChip, 'class1'));
    await tester.pumpAndSettle();

    // Verify the first chip is selected and the second is not
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class1')).selected, isTrue);
    expect(tester.widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'class2')).selected, isFalse);
  });
}
