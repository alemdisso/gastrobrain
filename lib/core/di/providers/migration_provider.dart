import '../../../core/providers/migration_provider.dart';

/// Provider for migration-related services in the dependency injection system
class MigrationServiceProvider {
  // Singleton instance
  static MigrationProvider? _migrationProvider;

  /// Get the migration provider instance
  MigrationProvider get provider {
    _migrationProvider ??= MigrationProvider();
    return _migrationProvider!;
  }

  /// Reset the provider (useful for testing)
  void reset() {
    _migrationProvider = null;
  }
}