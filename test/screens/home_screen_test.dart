import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide DatabaseExecutor;
import 'package:gastrobrain/core/di/service_provider.dart';
import 'package:gastrobrain/core/migration/migration.dart';
import 'package:gastrobrain/core/migration/migrations/001_initial_schema.dart';
import 'package:gastrobrain/core/migration/migrations/005_add_tags.dart';
import 'package:gastrobrain/core/migration/migrations/006_add_meal_role_food_type.dart';
import 'package:gastrobrain/core/migration/migrations/008_add_sauce_food_type.dart';
import 'package:gastrobrain/core/repositories/tag_repository.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';
import 'package:gastrobrain/screens/home_screen.dart';
import '../mocks/mock_database_helper.dart';

/// Fake [MockDatabaseHelper] that reports a pending migration failure
/// without touching the real database, avoiding FFI/isolate calls during
/// initState's postFrameCallback (which deadlocks flutter_test's FakeAsync).
class _PendingMigrationFailureDatabaseHelper extends MockDatabaseHelper {
  @override
  Future<bool> hasPendingMigrationFailure() async => true;
}

/// Fake [TagRepository] that reports an incomplete vocabulary without
/// touching the real database, avoiding FFI/isolate calls during
/// initState's postFrameCallback (which deadlocks flutter_test's FakeAsync).
class _IncompleteVocabTagRepository extends TagRepository {
  _IncompleteVocabTagRepository(super.dbHelper);

  bool repairCalled = false;

  @override
  Future<bool> hasIncompleteBuiltInVocabulary() async => true;

  @override
  Future<void> repairBuiltInVocabulary() async {
    repairCalled = true;
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  late Database db;
  late MockDatabaseHelper mockDbHelper;

  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('pt', ''),
      ],
      home: child,
    );
  }

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    final wrapper = DatabaseWrapper(db);
    await InitialSchemaMigration().up(wrapper);
    await AddTagsMigration().up(wrapper);
    await AddMealRoleFoodTypeMigration().up(wrapper);
    await AddSauceFoodTypeMigration().up(wrapper);

    mockDbHelper = MockDatabaseHelper();
    mockDbHelper.setDatabase(db);
    ServiceProvider.database.setDatabaseHelper(mockDbHelper);
  });

  tearDown(() async {
    await db.close();
    mockDbHelper.resetAllData();
  });

  testWidgets('healthy vocabulary shows no Repair SnackBar', (tester) async {
    await tester.pumpWidget(
        createTestableWidget(HomePage(databaseHelper: mockDbHelper)));
    await tester.pumpAndSettle();

    expect(find.text('Repair'), findsNothing);
  });

  testWidgets('incomplete vocabulary shows Repair SnackBar with warning',
      (tester) async {
    final fakeRepository = _IncompleteVocabTagRepository(mockDbHelper);

    await tester.pumpWidget(createTestableWidget(HomePage(
      databaseHelper: mockDbHelper,
      tagRepository: fakeRepository,
    )));
    await tester.pumpAndSettle();

    expect(
      find.text('Some built-in tags are missing. Tap Repair to restore them.'),
      findsOneWidget,
    );
    expect(find.text('Repair'), findsOneWidget);
  });

  testWidgets('tapping Repair calls repairBuiltInVocabulary', (tester) async {
    final fakeRepository = _IncompleteVocabTagRepository(mockDbHelper);

    await tester.pumpWidget(createTestableWidget(HomePage(
      databaseHelper: mockDbHelper,
      tagRepository: fakeRepository,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Repair'));
    await tester.pumpAndSettle();

    expect(fakeRepository.repairCalled, isTrue);
  });

  testWidgets(
      'migration failure and incomplete vocabulary warnings both fire without crashing',
      (tester) async {
    final fakeDbHelper = _PendingMigrationFailureDatabaseHelper();
    fakeDbHelper.setDatabase(db);
    final fakeTagRepository = _IncompleteVocabTagRepository(fakeDbHelper);

    await tester.pumpWidget(createTestableWidget(HomePage(
      databaseHelper: fakeDbHelper,
      tagRepository: fakeTagRepository,
    )));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.text(
          'A database update failed. Some features may not work correctly.'),
      findsOneWidget,
    );
  });
}
