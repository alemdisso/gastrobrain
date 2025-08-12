// IN: lib/core/di/service_provider.dart
import 'package:gastrobrain/core/di/providers/database_provider.dart';
import 'package:gastrobrain/core/di/providers/recommendation_provider.dart';
import 'package:gastrobrain/core/di/providers/migration_provider.dart';
import 'package:gastrobrain/core/di/providers/export_provider.dart';

/// Central hub for accessing all application services
class ServiceProvider {
  // Private constructor for singleton
  ServiceProvider._();

  // Static access to providers
  static DatabaseProvider get database => DatabaseProvider();
  static RecommendationProvider get recommendations => RecommendationProvider();
  static MigrationServiceProvider get migration => MigrationServiceProvider();
  static ExportProvider get export => ExportProvider();

  // You can add more services here as needed
}
