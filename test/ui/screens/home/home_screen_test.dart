import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:label_lab/data/models/project_model.dart';
import 'package:label_lab/services/project_service.dart';
import 'package:label_lab/ui/screens/home/home_screen.dart';
import 'package:label_lab/ui/screens/home/new_project_dialog.dart';
import 'package:label_lab/l10n/app_localizations.dart';

// Generate a MockProjectService class.
@GenerateMocks([ProjectService])
import 'home_screen_test.mocks.dart';

// A helper function to wrap the widget under test with necessary providers and MaterialApp
Widget createHomeScreen() {
  return const MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: HomeScreen(),
  );
}

void main() {
  group('HomeScreen Widget Tests', () {
    late MockProjectService mockProjectService;

    // Create a list of projects to be used in tests
    final List<Project> testProjects = [
      Project(id: '1', name: 'Project Alpha', projectPath: '/alpha'),
      Project(id: '2', name: 'Project Beta', projectPath: '/beta'),
    ];

    setUp(() {
      mockProjectService = MockProjectService();
      // Provide a default stub for saveProjects to avoid errors in tests that don't need it.
      when(mockProjectService.saveProjects(any)).thenAnswer((_) async {});
    });

    // Test to verify that projects are displayed correctly
    testWidgets('displays projects list when service returns data', (WidgetTester tester) async {
      // Arrange: Configure the mock service to return our test projects
      when(mockProjectService.getProjects()).thenAnswer((_) async => testProjects);

      // Act: Pump the widget tree
      await tester.pumpWidget(
        Provider<ProjectService>.value(
          value: mockProjectService,
          child: createHomeScreen(),
        ),
      );
      
      // Let the widget rebuild after the projects have been loaded.
      await tester.pumpAndSettle();

      // Assert: Check that both project names are found
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsOneWidget);
    });

    // Test to verify search functionality
    testWidgets('filters projects when user types in search bar', (WidgetTester tester) async {
      // Arrange
      when(mockProjectService.getProjects()).thenAnswer((_) async => testProjects);
      
      await tester.pumpWidget(
        Provider<ProjectService>.value(
          value: mockProjectService,
          child: createHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Find the search text field and enter text
      await tester.enterText(find.byType(TextField), 'Alpha');
      await tester.pump(); // Rebuild the widget with the filtered list

      // Assert: Verify that only the matching project is visible
      expect(find.text('Project Alpha'), findsOneWidget);
      expect(find.text('Project Beta'), findsNothing);
    });

    // Test to verify that the NewProjectDialog is shown
    testWidgets('shows NewProjectDialog when FloatingActionButton is tapped', (WidgetTester tester) async {
      // Arrange
      when(mockProjectService.getProjects()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        Provider<ProjectService>.value(
          value: mockProjectService,
          child: createHomeScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Act: Find the floating action button and tap it
      await tester.tap(find.byType(FloatingActionButton));
      
      // Use pump() instead of pumpAndSettle() to avoid timeouts with dialog animations.
      // This renders the first frame of the dialog, which is enough to find it.
      await tester.pump();

      // Assert: Check that the dialog is now visible
      expect(find.byType(NewProjectDialog), findsOneWidget);
    });
  });
}
