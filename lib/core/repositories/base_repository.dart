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