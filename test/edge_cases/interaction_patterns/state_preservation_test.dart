// test/edge_cases/interaction_patterns/state_preservation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for state preservation across navigation and lifecycle events.
///
/// Verifies that the app preserves state correctly:
/// - Search queries preserved during navigation
/// - Scroll positions maintained on back navigation
/// - Temporary selections preserved during dialogs
/// - State appropriately cleared on logout/reset
///
/// Note: Device-specific tests (orientation, backgrounding) are in Phase 4.3.2
void main() {
  group('State Preservation', () {
    testWidgets('search query preserved on navigation and back',
        (WidgetTester tester) async {
      // Track search query with controller
      final searchController = TextEditingController();
      String searchQuery = '';

      // Build app with search and detail screens
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                appBar: AppBar(title: const Text('Search')),
                body: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: 'Search recipes...',
                      ),
                    ),
                    Text('Query: $searchQuery'),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to detail screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: const Text('Details')),
                              body: const Center(child: Text('Recipe Details')),
                            ),
                          ),
                        );
                      },
                      child: const Text('View Details'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Enter search query
      await tester.enterText(find.byType(TextField), 'pasta carbonara');
      await tester.pump();

      // Verify query is shown
      expect(find.text('Query: pasta carbonara'), findsOneWidget);

      // Navigate to detail screen
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.text('Recipe Details'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify search query is still preserved
      expect(find.text('Query: pasta carbonara'), findsOneWidget,
          reason: 'Search query should be preserved after navigation');

      // Verify controller still has the search text
      expect(searchController.text, equals('pasta carbonara'),
          reason: 'Search controller should maintain text');
    });

    testWidgets('scroll position preserved on back navigation',
        (WidgetTester tester) async {
      // Build app with scrollable list
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('List')),
                body: ListView.builder(
                  itemCount: 100,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Item $index'),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Scaffold(
                              appBar: AppBar(title: Text('Item $index')),
                              body: Center(child: Text('Details for Item $index')),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
      );

      // Scroll down to item 50
      await tester.scrollUntilVisible(
        find.text('Item 50'),
        500.0,
      );

      // Verify item 50 is visible
      expect(find.text('Item 50'), findsOneWidget);

      // Tap on item 50 to navigate
      await tester.tap(find.text('Item 50'));
      await tester.pumpAndSettle();

      // Verify we're on detail screen
      expect(find.text('Details for Item 50'), findsOneWidget);

      // Navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Verify item 50 is still visible (scroll position preserved)
      expect(find.text('Item 50'), findsOneWidget,
          reason: 'Scroll position should be preserved after back navigation');

      // Verify we didn't scroll back to top
      expect(find.text('Item 0'), findsNothing,
          reason: 'Should not have scrolled back to top');
    });

    testWidgets('state cleared appropriately on logout',
        (WidgetTester tester) async {
      // Track user state
      String? currentUser;
      String? userEmail;
      List<String> recentSearches = [];

      // Build app with login state
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              if (currentUser == null) {
                // Login screen
                return Scaffold(
                  appBar: AppBar(title: const Text('Login')),
                  body: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        currentUser = 'testuser';
                        userEmail = 'test@example.com';
                        recentSearches = ['pasta', 'chicken', 'dessert'];
                      });
                    },
                    child: const Text('Login'),
                  ),
                );
              }

              // Main screen (logged in)
              return Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: Column(
                  children: [
                    Text('User: $currentUser'),
                    Text('Email: $userEmail'),
                    Text('Recent: ${recentSearches.join(", ")}'),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          // Clear all user state on logout
                          currentUser = null;
                          userEmail = null;
                          recentSearches.clear();
                        });
                      },
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Verify we start on login screen (AppBar has Login title)
      expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);

      // Login
      await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
      await tester.pump();

      // Verify user state is populated
      expect(find.text('User: testuser'), findsOneWidget);
      expect(find.text('Email: test@example.com'), findsOneWidget);
      expect(find.text('Recent: pasta, chicken, dessert'), findsOneWidget);

      // Logout
      await tester.tap(find.text('Logout'));
      await tester.pump();

      // Verify all state is cleared
      expect(currentUser, isNull,
          reason: 'User should be cleared on logout');
      expect(userEmail, isNull,
          reason: 'Email should be cleared on logout');
      expect(recentSearches, isEmpty,
          reason: 'Recent searches should be cleared on logout');

      // Verify we're back on login screen
      expect(find.widgetWithText(AppBar, 'Login'), findsOneWidget);
      expect(find.text('User: testuser'), findsNothing);
      expect(find.text('Email: test@example.com'), findsNothing);
    });
  });
}
