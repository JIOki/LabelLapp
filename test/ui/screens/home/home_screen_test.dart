import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:label_lab/data/models/project_model.dart';
import 'package:label_lab/services/project_service.dart';
import 'package:label_lab/ui/screens/home/home_screen.dart';
import 'package:label_lab/ui/screens/home/new_project_dialog.dart';

@GenerateMocks([ProjectService])
import 'home_screen_test.mocks.dart';

Widget createTestableWidget({
  required Widget child,
  required ProjectService projectService,
}) {
  return Provider<ProjectService>.value(
    value: projectService,
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  // DEFINITIVE FIX: Mock permission handler to avoid permission dialogs in tests.
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    const MethodChannel channel = MethodChannel('flutter.baseflow.com/permissions/methods');

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'requestPermissions') {
        return <int, int>{0: 1}; // Grant all requested permissions
      }
      if (methodCall.method == 'checkPermissionStatus') {
        return 1; // Return 'granted' status
      }
      return null;
    });
  });

  group('HomeScreen Widget Tests', () {
    late MockProjectService mockProjectService;

    final List<Project> testProjects = [
      Project(id: '1', name: 'Project Alpha', projectPath: '/alpha'),
      Project(id: '2', name: 'Project Beta', projectPath: '/beta'),
    ];

    setUp(() {
      mockProjectService = MockProjectService();
      when(mockProjectService.saveProjects(any)).thenAnswer((_) async {});
    });

    testWidgets('displays projects list when service returns data', (WidgetTester tester) async {
      when(mockProjectService.getProjects()).thenAnswer((_) async => testProjects);

      await tester.pumpWidget(createTestableWidget(
        projectService: mockProjectService,
        child: const HomeScreen(),
      ));
      
      await tester.pumpAndSettle();

      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsOneWidget);
    });

    testWidgets('filters projects when user types in search bar', (WidgetTester tester) async {
      when(mockProjectService.getProjects()).thenAnswer((_) async => testProjects);

      await tester.pumpWidget(createTestableWidget(
        projectService: mockProjectService,
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pumpAndSettle();

      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsNothing);
    });

    testWidgets('shows NewProjectDialog when FloatingActionButton is tapped', (WidgetTester tester) async {
      when(mockProjectService.getProjects()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestableWidget(
        projectService: mockProjectService,
        child: const HomeScreen(),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle(); // This pump is needed for the dialog to appear

      expect(find.byType(NewProjectDialog), findsOneWidget);
    });
  });
}
