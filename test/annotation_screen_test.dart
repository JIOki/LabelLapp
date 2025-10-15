import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:labellab/models/annotation.dart';
import 'package:labellab/models/bounding_box.dart';
import 'package:labellab/models/image.dart';
import 'package:labellab/models/project.dart';
import 'package:labellab/ui/screens/annotation/annotation_screen.dart';

// A 1x1 transparent PNG
final kTestImageBytes = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

void main() {
  testWidgets('AnnotationScreen renders correctly', (WidgetTester tester) async {
    final project = Project(name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(name: 'Test Image', bytes: kTestImageBytes);

    await tester.pumpWidget(MaterialApp(
      home: AnnotationScreen(image: image, project: project),
    ));

    expect(find.text('Test Image'), findsOneWidget);
    expect(find.byIcon(Icons.save), findsOneWidget);
  });

  testWidgets('Tapping save button pops the navigator', (WidgetTester tester) async {
    final project = Project(name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
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

  testWidgets('Editing a label updates the state', (WidgetTester tester) async {
    final project = Project(name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(
      name: 'Test Image',
      bytes: kTestImageBytes,
      annotation: Annotation(
        boxes: [
          BoundingBox(left: 0, top: 0, right: 10, bottom: 10, label: 'class1'),
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: AnnotationScreen(image: image, project: project),
    ));

    final editIconFinder = find.descendant(of: find.widgetWithText(Card, 'class1'), matching: find.byIcon(Icons.edit));
    await tester.ensureVisible(editIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(editIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Tap on the second class in the dialog
    await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text('class2')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify the label in the sidebar has been updated
    expect(find.descendant(of: find.byType(Card), matching: find.text('class2')), findsOneWidget);
  });

  testWidgets('Edit label dialog shows project classes', (WidgetTester tester) async {
    final project = Project(name: 'Test Project', projectPath: '/tmp', classes: ['class1', 'class2']);
    final image = ProjectImage(
      name: 'Test Image',
      bytes: kTestImageBytes,
      annotation: Annotation(
        boxes: [
          BoundingBox(left: 0, top: 0, right: 10, bottom: 10, label: 'class1'),
        ],
      ),
    );

    await tester.pumpWidget(MaterialApp(
      home: AnnotationScreen(image: image, project: project),
    ));

    // The sidebar shows the initial label within a Card
    expect(find.descendant(of: find.byType(Card), matching: find.text('class1')), findsOneWidget);

    final editIconFinder = find.descendant(of: find.widgetWithText(Card, 'class1'), matching: find.byIcon(Icons.edit));
    await tester.ensureVisible(editIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(editIconFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify both classes are shown in the dialog
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('class1')), findsOneWidget);
    expect(find.descendant(of: find.byType(AlertDialog), matching: find.text('class2')), findsOneWidget);
  });
}
