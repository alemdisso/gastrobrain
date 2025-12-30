// test/edge_cases/interaction_patterns/navigation_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for navigation edge cases and complex navigation flows.
///
/// Verifies that the app handles scenarios involving:
/// - Deep navigation stacks
/// - Back button navigation
/// - Invalid routes and parameters
/// - Navigation to deleted/missing items
/// - Stale data after navigation
///
/// Note: These tests verify navigation patterns, not full feature workflows.
void main() {
  group('Navigation Sequences', () {
    testWidgets('deep navigation stack handles 10+ screens',
        (WidgetTester tester) async {
      // Track current depth
      int currentDepth = 0;

      // Helper to build screen at any depth
      Widget buildScreen(int depth) {
        return Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: Text('Screen $depth')),
              body: Column(
                children: [
                  Text('Depth: $depth'),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => buildScreen(depth + 1),
                        ),
                      );
                    },
                    child: const Text('Go Deeper'),
                  ),
                ],
              ),
            );
          },
        );
      }

      // Build app starting at depth 0
      await tester.pumpWidget(
        MaterialApp(
          home: buildScreen(currentDepth),
        ),
      );

      // Navigate 12 levels deep
      for (int i = 0; i < 12; i++) {
        await tester.tap(find.text('Go Deeper'));
        await tester.pumpAndSettle();
        currentDepth++;
      }

      // Verify we're at depth 12
      expect(find.text('Depth: 12'), findsOneWidget,
          reason: 'Should be able to navigate 12 levels deep');

      // Verify screen title
      expect(find.text('Screen 12'), findsOneWidget);

      // Verify we can still navigate (no crash or performance issue)
      expect(tester.takeException(), isNull,
          reason: 'Deep navigation should not cause crashes');
    });

    testWidgets('back button navigates through entire stack',
        (WidgetTester tester) async {
      // Helper to build numbered screens
      Widget buildScreen(int number) {
        return Builder(
          builder: (context) {
            return Scaffold(
              appBar: AppBar(title: Text('Screen $number')),
              body: Column(
                children: [
                  Text('Level $number'),
                  if (number < 5)
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => buildScreen(number + 1),
                          ),
                        );
                      },
                      child: const Text('Next'),
                    ),
                ],
              ),
            );
          },
        );
      }

      // Build app
      await tester.pumpWidget(
        MaterialApp(home: buildScreen(1)),
      );

      // Navigate to level 5
      for (int i = 1; i < 5; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // Verify we're at level 5
      expect(find.text('Level 5'), findsOneWidget);

      // Navigate back through all screens
      for (int level = 5; level > 1; level--) {
        // Press back button
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Verify we're at the previous level
        expect(find.text('Level ${level - 1}'), findsOneWidget,
            reason: 'Should navigate back to level ${level - 1}');
      }

      // Verify we're back at level 1
      expect(find.text('Level 1'), findsOneWidget);
      expect(find.text('Screen 1'), findsOneWidget);
    });

    testWidgets('navigate to deleted item shows error gracefully',
        (WidgetTester tester) async {
      // Track available items
      final Map<int, String> items = {
        1: 'Item 1',
        2: 'Item 2',
        3: 'Item 3',
      };

      // Build app with item list and detail view
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Item List')),
                body: Column(
                  children: items.entries.map((entry) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => Builder(
                              builder: (context) {
                                // Simulate item not found
                                if (!items.containsKey(entry.key)) {
                                  return Scaffold(
                                    appBar: AppBar(title: const Text('Error')),
                                    body: const Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, size: 64),
                                          SizedBox(height: 16),
                                          Text('Item not found'),
                                          Text(
                                              'This item may have been deleted'),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                return Scaffold(
                                  appBar:
                                      AppBar(title: Text(items[entry.key]!)),
                                  body: Center(
                                    child:
                                        Text('Details for ${items[entry.key]}'),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: Text('View ${entry.value}'),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ),
      );

      // Navigate to item 2
      await tester.tap(find.text('View Item 2'));
      await tester.pumpAndSettle();

      // Verify we see the detail view
      expect(find.text('Details for Item 2'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Delete item 2
      items.remove(2);

      // Try to navigate to deleted item 2
      await tester.tap(find.text('View Item 2'));
      await tester.pumpAndSettle();

      // Verify error screen is shown
      expect(find.text('Item not found'), findsOneWidget);
      expect(find.text('This item may have been deleted'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);

      // Verify app didn't crash
      expect(tester.takeException(), isNull);

      // Verify we can navigate back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Item List'), findsOneWidget);
    });

    testWidgets('navigate with invalid parameters shows error',
        (WidgetTester tester) async {
      // Build app with parameterized route
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Navigate with valid ID
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _DetailScreen(id: 42),
                          ),
                        );
                      },
                      child: const Text('Valid ID'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate with invalid ID (negative)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const _DetailScreen(id: -1),
                          ),
                        );
                      },
                      child: const Text('Invalid ID'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // Navigate with valid ID
      await tester.tap(find.text('Valid ID'));
      await tester.pumpAndSettle();

      // Verify valid screen is shown
      expect(find.text('Details for ID: 42'), findsOneWidget);

      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Navigate with invalid ID
      await tester.tap(find.text('Invalid ID'));
      await tester.pumpAndSettle();

      // Verify error is shown
      expect(find.text('Invalid Parameter'), findsOneWidget);
      expect(find.text('ID must be positive'), findsOneWidget);

      // Verify app didn't crash
      expect(tester.takeException(), isNull);

      // Verify we can go back
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Home'), findsOneWidget);
    });
  });
}

// Helper widget for parameterized navigation test
class _DetailScreen extends StatelessWidget {
  final int id;

  const _DetailScreen({required this.id});

  @override
  Widget build(BuildContext context) {
    // Validate parameter
    if (id < 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text('Invalid Parameter'),
              Text('ID must be positive'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Detail $id')),
      body: Center(
        child: Text('Details for ID: $id'),
      ),
    );
  }
}
