import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:label_lab/data/models/image_model.dart';
import 'package:label_lab/data/models/project_model.dart';
import 'package:label_lab/services/project_service.dart';
import 'package:label_lab/ui/screens/annotation/annotation_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'annotation_screen_test.mocks.dart';

final kTestImageBytes = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=');

@GenerateMocks([ProjectService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockProjectService mockProjectService;

  setUpAll(() {
    const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        return <int, int>{0: 1};
      }
      if (methodCall.method == 'checkPermissionStatus') {
        return 1;
      }
      return null;
    });
  });

  setUp(() {
    mockProjectService = MockProjectService();
    when(mockProjectService.saveLabelForImage(
      projectPath: anyNamed('projectPath'),
      imageName: anyNamed('imageName'),
      yoloString: anyNamed('yoloString'),
    )).thenAnswer((_) async => true);
  });

  final project = Project(
    id: '1',
    name: 'Test Project',
    projectPath: '/tmp',
    classes: ['class1', 'class2'],
  );

  final images = [ProjectImage(name: 'Image 1.jpg', bytes: kTestImageBytes)];

  testWidgets('Popping the screen triggers save', (WidgetTester tester) async {
    // Arrange
    await tester.pumpWidget(
      Provider<ProjectService>.value(
        value: mockProjectService,
        child: MaterialApp(
          home: AnnotationScreen(images: images, project: project, initialIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Act: Use tester.pageBack() to simulate popping the route.
    // This correctly triggers the WillPopScope.
    await tester.pageBack();
    
    // DEFINITIVE FIX: Removed the unnecessary pumpAndSettle that was causing a timeout.
    // The await on pageBack is sufficient.

    // Assert: Verify save was called.
    verify(mockProjectService.saveLabelForImage(
      projectPath: project.projectPath,
      imageName: images[0].name,
      yoloString: ''
    )).called(1);
  });
}
