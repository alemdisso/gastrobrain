// test/edge_cases/interaction_patterns/rapid_tap_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for rapid tap interactions and debouncing.
///
/// Verifies that rapid user interactions are handled gracefully:
/// - Duplicate operations prevented
/// - Debouncing works correctly
/// - Loading states prevent multiple taps
/// - UI remains responsive
///
/// Note: These tests verify interaction patterns, not full feature workflows.
void main() {
  group('Rapid Tap Testing', () {
    testWidgets('save button tapped 10 times rapidly prevents duplicate saves',
        (WidgetTester tester) async {
      // Track how many times save was called
      int saveCallCount = 0;
      bool isSaving = false;

      // Build a simple widget with a save button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          // Prevent duplicate taps while saving
                          if (isSaving) return;

                          setState(() {
                            isSaving = true;
                          });

                          saveCallCount++;

                          // Simulate async save operation
                          await Future.delayed(const Duration(milliseconds: 100));

                          setState(() {
                            isSaving = false;
                          });
                        },
                  child: const Text('Save'),
                );
              },
            ),
          ),
        ),
      );

      // Rapidly tap the save button 10 times
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Save'));
        // Don't pump between taps to simulate truly rapid taps
      }

      // Pump to let the first save start
      await tester.pump();

      // Wait for save operation to complete
      await tester.pumpAndSettle();

      // Verify save was only called once despite 10 rapid taps
      expect(saveCallCount, equals(1),
          reason: 'Save should only be called once despite rapid taps');
    });

    testWidgets('add recipe button tapped multiple times prevents duplicate navigation',
        (WidgetTester tester) async {
      // Track navigation attempts
      int navigationCallCount = 0;
      bool isNavigating = false;

      // Build a simple widget with an add recipe button
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: isNavigating
                      ? null
                      : () async {
                          // Prevent duplicate navigation
                          if (isNavigating) return;

                          isNavigating = true;
                          navigationCallCount++;

                          // Simulate navigation delay
                          await Future.delayed(const Duration(milliseconds: 50));

                          // In a real app, would navigate here
                          // Navigator.of(context).push(...);

                          isNavigating = false;
                        },
                  child: const Text('Add Recipe'),
                ),
              );
            },
          ),
        ),
      );

      // Rapidly tap the add recipe button 5 times
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.text('Add Recipe'));
        // Don't pump between taps to simulate rapid taps
      }

      // Pump to start the first navigation
      await tester.pump();

      // Wait for navigation to complete
      await tester.pumpAndSettle();

      // Verify navigation was only attempted once
      expect(navigationCallCount, equals(1),
          reason: 'Should only navigate once despite rapid taps');
    });

    testWidgets('delete button tapped rapidly shows confirmation dialog only once',
        (WidgetTester tester) async {
      // Track how many dialogs were shown
      int dialogShowCount = 0;
      bool isShowingDialog = false;

      // Build a simple widget with a delete button
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: isShowingDialog
                      ? null
                      : () async {
                          // Prevent duplicate dialogs
                          if (isShowingDialog) return;

                          isShowingDialog = true;
                          dialogShowCount++;

                          // Show confirmation dialog
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Confirm Delete'),
                              content: const Text('Are you sure?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );

                          isShowingDialog = false;
                        },
                  child: const Text('Delete'),
                ),
              );
            },
          ),
        ),
      );

      // Rapidly tap the delete button 7 times
      for (int i = 0; i < 7; i++) {
        await tester.tap(find.text('Delete'));
        // Don't pump between taps to simulate rapid taps
      }

      // Pump to show the dialog
      await tester.pumpAndSettle();

      // Verify dialog was only shown once
      expect(dialogShowCount, equals(1),
          reason: 'Confirmation dialog should only appear once despite rapid taps');

      // Verify only one dialog is visible
      expect(find.text('Confirm Delete'), findsOneWidget);

      // Cancel the dialog to clean up
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('navigation button rapid taps navigates only once',
        (WidgetTester tester) async {
      // Track navigation count
      int navigationCount = 0;
      bool isNavigating = false;

      // Build app with navigation button
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                appBar: AppBar(title: const Text('Home')),
                body: ElevatedButton(
                  onPressed: isNavigating
                      ? null
                      : () async {
                          // Prevent duplicate navigation
                          if (isNavigating) return;

                          isNavigating = true;
                          navigationCount++;

                          // Navigate to another screen
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => Scaffold(
                                appBar: AppBar(title: const Text('Details')),
                                body: const Center(child: Text('Details Screen')),
                              ),
                            ),
                          );

                          isNavigating = false;
                        },
                  child: const Text('View Details'),
                ),
              );
            },
          ),
        ),
      );

      // Rapidly tap navigation button 8 times
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.text('View Details'));
        // Don't pump between taps
      }

      // Pump to trigger navigation
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300)); // Navigation animation

      // Verify navigation happened only once
      expect(navigationCount, equals(1),
          reason: 'Should navigate only once despite rapid taps');

      // Verify we're on the details screen
      expect(find.text('Details Screen'), findsOneWidget);

      // Verify only one details screen exists (not multiple pushed)
      expect(find.text('Details'), findsOneWidget);
    });

    testWidgets('dialog open button tapped rapidly shows only one dialog',
        (WidgetTester tester) async {
      // Track how many dialogs were opened
      int dialogOpenCount = 0;
      bool isShowingDialog = false;

      // Build a simple widget with a button that opens an info dialog
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: isShowingDialog
                      ? null
                      : () async {
                          // Prevent duplicate dialogs
                          if (isShowingDialog) return;

                          isShowingDialog = true;
                          dialogOpenCount++;

                          // Show info dialog
                          await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Settings'),
                              content: const Text('Configure your preferences here.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                ),
                              ],
                            ),
                          );

                          isShowingDialog = false;
                        },
                  child: const Text('Open Settings'),
                ),
              );
            },
          ),
        ),
      );

      // Rapidly tap the settings button 6 times
      for (int i = 0; i < 6; i++) {
        await tester.tap(find.text('Open Settings'));
        // Don't pump between taps to simulate rapid taps
      }

      // Pump to show the dialog
      await tester.pumpAndSettle();

      // Verify dialog was only opened once
      expect(dialogOpenCount, equals(1),
          reason: 'Dialog should only open once despite rapid taps');

      // Verify only one dialog is visible
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Configure your preferences here.'), findsOneWidget);

      // Close the dialog to clean up
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    });

    testWidgets('star rating rapid taps handled gracefully',
        (WidgetTester tester) async {
      // Track state updates
      int stateUpdateCount = 0;
      int currentRating = 0;

      // Build a simple star rating widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      icon: Icon(
                        index < currentRating ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () {
                        setState(() {
                          currentRating = index + 1;
                          stateUpdateCount++;
                        });
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ),
      );

      // Rapidly tap different star buttons 15 times
      final starPositions = [0, 2, 4, 1, 3, 0, 4, 2, 1, 3, 4, 0, 2, 3, 1];
      for (final starIndex in starPositions) {
        await tester.tap(find.byType(IconButton).at(starIndex));
        // Don't pump between taps to simulate rapid taps
      }

      // Pump to process all taps
      await tester.pumpAndSettle();

      // Verify the widget handled rapid taps without crashing
      // State updates should equal number of taps processed
      expect(stateUpdateCount, greaterThan(0),
          reason: 'Rating should have been updated');

      // Verify final rating is valid (1-5)
      expect(currentRating, greaterThanOrEqualTo(1));
      expect(currentRating, lessThanOrEqualTo(5));

      // Verify correct number of filled stars are displayed
      expect(find.byIcon(Icons.star), findsNWidgets(currentRating));
      expect(find.byIcon(Icons.star_border), findsNWidgets(5 - currentRating));
    });

    testWidgets('calendar slot rapid taps handled gracefully',
        (WidgetTester tester) async {
      // Track selections
      int selectionCount = 0;
      int? selectedSlot;

      // Build a simple calendar-like grid with time slots
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2.0,
                  ),
                  itemCount: 9, // 9 time slots
                  itemBuilder: (context, index) {
                    final isSelected = selectedSlot == index;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          selectedSlot = index;
                          selectionCount++;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue : Colors.grey[200],
                          border: Border.all(color: Colors.grey),
                        ),
                        child: Center(
                          child: Text('Slot $index'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      );

      // Rapidly tap different calendar slots 12 times
      final slotSequence = [0, 3, 6, 1, 4, 7, 2, 5, 8, 0, 4, 8];
      for (final slot in slotSequence) {
        await tester.tap(find.text('Slot $slot'));
        // Don't pump between taps to simulate rapid taps
      }

      // Pump to process all taps
      await tester.pumpAndSettle();

      // Verify the widget handled rapid taps without crashing
      expect(selectionCount, greaterThan(0),
          reason: 'At least one slot should have been selected');

      // Verify a valid slot is selected (0-8)
      expect(selectedSlot, isNotNull);
      expect(selectedSlot!, greaterThanOrEqualTo(0));
      expect(selectedSlot!, lessThanOrEqualTo(8));

      // Verify the selected slot is highlighted
      // The selected slot should have a blue background
      final selectedWidget = tester.widget<Container>(
        find.ancestor(
          of: find.text('Slot $selectedSlot'),
          matching: find.byType(Container),
        ).first,
      );
      expect(selectedWidget.decoration, isA<BoxDecoration>());
      final decoration = selectedWidget.decoration as BoxDecoration;
      expect(decoration.color, equals(Colors.blue));
    });

    testWidgets('debouncing prevents duplicate operations',
        (WidgetTester tester) async {
      // Track actual operations executed
      int searchesExecuted = 0;
      bool isSearching = false;

      // Debounced search operation
      Future<void> performSearch() async {
        // Prevent duplicate searches (debouncing pattern)
        if (isSearching) return;

        isSearching = true;
        searchesExecuted++;

        // Simulate search operation
        await Future.delayed(const Duration(milliseconds: 200));

        isSearching = false;
      }

      // Build a simple widget with a search button
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ElevatedButton(
              onPressed: isSearching ? null : performSearch,
              child: const Text('Search'),
            ),
          ),
        ),
      );

      // Rapidly tap the search button 8 times
      for (int i = 0; i < 8; i++) {
        await tester.tap(find.text('Search'));
        // Don't pump between taps to simulate truly rapid taps
      }

      // Pump to start first search
      await tester.pump();

      // Wait for search operation to complete
      await tester.pumpAndSettle();

      // Verify debouncing worked - only one search executed
      expect(searchesExecuted, equals(1),
          reason: 'Debouncing should prevent duplicate searches despite rapid taps');

      // Tap again after first search completes
      await tester.tap(find.text('Search'));
      await tester.pump();
      await tester.pumpAndSettle();

      // Verify second search executed after first completed
      expect(searchesExecuted, equals(2),
          reason: 'Should allow new search after previous one completes');
    });

    testWidgets('loading state shown during operation',
        (WidgetTester tester) async {
      // Track loading state
      bool isLoading = false;

      // Build widget with loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isLoading)
                      const CircularProgressIndicator()
                    else
                      ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            isLoading = true;
                          });

                          // Simulate async operation
                          await Future.delayed(const Duration(milliseconds: 300));

                          setState(() {
                            isLoading = false;
                          });
                        },
                        child: const Text('Submit'),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Verify button is visible initially
      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // Tap the submit button
      await tester.tap(find.text('Submit'));
      await tester.pump(); // Start the operation

      // Verify loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget,
          reason: 'Loading indicator should be visible during operation');
      expect(find.text('Submit'), findsNothing,
          reason: 'Button should be hidden while loading');

      // Wait for operation to complete
      await tester.pumpAndSettle();

      // Verify loading indicator is hidden and button is back
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Submit'), findsOneWidget,
          reason: 'Button should reappear after operation completes');
    });
  });
}
