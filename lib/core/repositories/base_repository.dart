import '../errors/gastrobrain_exceptions.dart';

/// Base interface for all repositories providing common patterns
abstract class BaseRepository<T> {
  /// Indicates if data is currently being loaded
  bool get isLoading;

  /// Indicates if repository has cached data
  bool get hasData;

  /// Last error that occurred during operations
  GastrobrainException? get lastError;

  /// Clears cached data and forces fresh load on next request
  void invalidateCache();

  /// Clears any error state
  void clearError();

  /// Called when a database migration completes
  /// 
  /// Repositories should override this to handle migration-specific cache invalidation
  /// The default implementation calls invalidateCache() to be safe
  void onMigrationCompleted() {
    invalidateCache();
  }
}

/// Static registry for managing repository instances that need migration notifications
class RepositoryRegistry {
  static final List<BaseRepository> _repositories = [];
  
  /// Register a repository to receive migration notifications
  static void register(BaseRepository repository) {
    if (!_repositories.contains(repository)) {
      _repositories.add(repository);
    }
  }
  
  /// Unregister a repository from migration notifications
  static void unregister(BaseRepository repository) {
    _repositories.remove(repository);
  }
  
  /// Notify all registered repositories that a migration has completed
  static void notifyMigrationCompleted() {
    for (final repository in _repositories) {
      try {
        repository.onMigrationCompleted();
      } catch (e) {
        // Log error but don't let one repository failure break others
        print('Warning: Repository migration notification failed: $e');
      }
    }
  }
  
  /// Get count of registered repositories (for testing/debugging)
  static int get registeredCount => _repositories.length;
  
  /// Clear all registered repositories (for testing)
  static void clearAll() {
    _repositories.clear();
  }
}

/// Result wrapper for repository operations
class RepositoryResult<T> {
  final T? data;
  final GastrobrainException? error;
  final bool isLoading;

  const RepositoryResult._({
    this.data,
    this.error,
    this.isLoading = false,
  });

  /// Creates a successful result
  const RepositoryResult.success(T data) : this._(data: data);

  /// Creates an error result
  const RepositoryResult.error(GastrobrainException error) : this._(error: error);

  /// Creates a loading result
  const RepositoryResult.loading() : this._(isLoading: true);

  /// True if operation was successful
  bool get isSuccess => data != null && error == null;

  /// True if operation failed
  bool get isError => error != null;
}