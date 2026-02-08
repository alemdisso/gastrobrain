// test/test_utils/test_setup.dart

import 'package:gastrobrain/core/di/providers/database_provider.dart';
import '../mocks/mock_database_helper.dart';

/// Standardized test setup utility class for database mocking.
/// 
/// This class implements the pattern recommended in GitHub issue #30
/// to ensure consistent database mocking across all tests and prevent
/// database locking issues when running tests in parallel.
class TestSetup {
  /// Sets up a mock database for tests.
  /// 
  /// This method:
  /// 1. Creates a fresh MockDatabaseHelper instance
  /// 2. Injects it into the DatabaseProvider for dependency injection
  /// 3. Returns the mock helper for direct access if needed
  /// 
  /// Use this in test setUp() methods to ensure proper isolation.
  /// 
  /// Example:
  /// ```dart
  /// late MockDatabaseHelper mockDb;
  /// 
  /// setUp(() {
  ///   mockDb = TestSetup.setupMockDatabase();
  /// });
  /// ```
  static MockDatabaseHelper setupMockDatabase() {
    final mockDbHelper = MockDatabaseHelper();
    DatabaseProvider().setDatabaseHelper(mockDbHelper);
    return mockDbHelper;
  }
  
  /// Cleans up the mock database after tests.
  /// 
  /// This method resets all data in the mock database to ensure
  /// clean state between tests when running in parallel.
  /// 
  /// Use this in test tearDown() methods.
  /// 
  /// Example:
  /// ```dart
  /// tearDown(() {
  ///   TestSetup.cleanupMockDatabase(mockDb);
  /// });
  /// ```
  static void cleanupMockDatabase(MockDatabaseHelper mockDbHelper) {
    mockDbHelper.resetAllData();
  }
  
  /// Sets up a mock database with pre-populated test data.
  /// 
  /// This is a convenience method for tests that need common test data.
  /// Currently returns an empty mock - specific tests should populate
  /// their own data as needed.
  /// 
  /// Future enhancement: Could add common test data patterns here.
  static MockDatabaseHelper setupMockDatabaseWithTestData() {
    final mockDbHelper = setupMockDatabase();
    return mockDbHelper;
  }
}