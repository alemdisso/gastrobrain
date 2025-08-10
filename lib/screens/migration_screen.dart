import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/providers/migration_provider.dart';
import '../core/di/service_provider.dart';
import '../l10n/app_localizations.dart';

/// Screen for managing database migrations with user feedback
/// 
/// This screen provides:
/// - Migration status display
/// - Progress tracking during migrations
/// - Error handling and recovery options
/// - Migration history viewing
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  late MigrationProvider _migrationProvider;

  @override
  void initState() {
    super.initState();
    _migrationProvider = ServiceProvider.migration.provider;
    
    // Initialize provider when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _migrationProvider.initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _migrationProvider,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.titleDatabaseMigration),
          actions: [
            Consumer<MigrationProvider>(
              builder: (context, provider, child) {
                return IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: provider.isMigrating ? null : () => provider.refresh(),
                  tooltip: AppLocalizations.of(context)!.buttonRefresh,
                );
              },
            ),
          ],
        ),
        body: Consumer<MigrationProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStatusCard(context, provider),
                  const SizedBox(height: 16),
                  if (provider.isMigrating) _buildProgressCard(context, provider),
                  if (provider.error != null) _buildErrorCard(context, provider),
                  if (provider.migrationResults.isNotEmpty) 
                    _buildResultsCard(context, provider),
                  const SizedBox(height: 16),
                  _buildActionButtons(context, provider),
                  const SizedBox(height: 16),
                  Expanded(child: _buildMigrationHistory(context, provider)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, MigrationProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labelDatabaseStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  provider.needsMigration 
                      ? Icons.warning 
                      : Icons.check_circle,
                  color: provider.needsMigration 
                      ? Theme.of(context).colorScheme.error 
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  provider.needsMigration 
                      ? l10n.statusMigrationNeeded 
                      : l10n.statusUpToDate,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${l10n.labelCurrentVersion}: ${provider.currentVersion}'),
            Text('${l10n.labelLatestVersion}: ${provider.latestVersion}'),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(BuildContext context, MigrationProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.labelMigrationProgress,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: provider.progress,
            ),
            const SizedBox(height: 8),
            Text(provider.currentStatus),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, MigrationProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.errorMigrationFailed,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              provider.error!.message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => provider.clearError(),
              child: Text(l10n.buttonDismiss),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard(BuildContext context, MigrationProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labelMigrationResults,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(provider.getResultSummary()),
            const SizedBox(height: 8),
            ...provider.getDetailedResults().map((result) => 
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2.0),
                child: Text(
                  result,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, MigrationProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Wrap(
      spacing: 8.0,
      children: [
        ElevatedButton.icon(
          onPressed: provider.isMigrating || !provider.needsMigration 
              ? null 
              : () => _runMigrations(provider),
          icon: const Icon(Icons.upgrade),
          label: Text(l10n.buttonRunMigrations),
        ),
        if (provider.currentVersion > 1)
          ElevatedButton.icon(
            onPressed: provider.isMigrating 
                ? null 
                : () => _showRollbackDialog(context, provider),
            icon: const Icon(Icons.undo),
            label: Text(l10n.buttonRollback),
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    );
  }

  Widget _buildMigrationHistory(BuildContext context, MigrationProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.labelMigrationHistory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.migrationHistory.isEmpty
                  ? Center(
                      child: Text(l10n.messageNoMigrationHistory),
                    )
                  : ListView.builder(
                      itemCount: provider.migrationHistory.length,
                      itemBuilder: (context, index) {
                        final migration = provider.migrationHistory[index];
                        return ListTile(
                          leading: const Icon(Icons.check_circle),
                          title: Text('${l10n.labelVersion} ${migration['version']}'),
                          subtitle: Text(migration['description'] ?? ''),
                          trailing: Text(
                            migration['applied_at'] ?? '',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runMigrations(MigrationProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.titleConfirmMigration),
        content: Text(l10n.messageMigrationWarning),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.buttonContinue),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await provider.runMigrations();
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageMigrationSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }

  Future<void> _showRollbackDialog(BuildContext context, MigrationProvider provider) async {
    final l10n = AppLocalizations.of(context)!;
    
    final targetVersion = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.titleRollbackDatabase),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.messageRollbackWarning),
            const SizedBox(height: 16),
            Text('${l10n.labelCurrentVersion}: ${provider.currentVersion}'),
            const SizedBox(height: 8),
            TextField(
              decoration: InputDecoration(
                labelText: l10n.labelTargetVersion,
                hintText: '1',
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                // Store the target version for rollback
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.buttonCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(1), // Simplified for demo
            style: ElevatedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.buttonRollback),
          ),
        ],
      ),
    );

    if (targetVersion != null && mounted) {
      final success = await provider.rollbackToVersion(targetVersion);
      
      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.messageRollbackSuccess),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    }
  }
}