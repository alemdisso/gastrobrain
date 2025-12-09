import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../l10n/app_localizations.dart';
import '../core/di/service_provider.dart';
import '../core/services/snackbar_service.dart';
import '../core/errors/gastrobrain_exceptions.dart';

/// Temporary tools screen for development utilities
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  bool _isBackingUp = false;
  bool _isRestoring = false;
  bool _isImportingRecipes = false;
  bool _isExportingRecipes = false;
  bool _isExportingIngredients = false;

  Future<void> _exportRecipes() async {
    if (_isExportingRecipes) return;

    setState(() {
      _isExportingRecipes = true;
    });

    try {
      final exportService = ServiceProvider.export.recipeExport;
      final filePath = await exportService.exportRecipesToJson();

      if (mounted) {
        SnackbarService.showSuccess(
          context,
          'Recipes exported successfully!\nFile: $filePath',
        );

        // Copy file path to clipboard for easy access
        await Clipboard.setData(ClipboardData(text: filePath));

        // Show additional info
        _showExportSuccessDialog(filePath);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Failed to export recipes: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingRecipes = false;
        });
      }
    }
  }

  Future<void> _exportIngredients() async {
    if (_isExportingIngredients) return;

    setState(() {
      _isExportingIngredients = true;
    });

    try {
      final exportService = ServiceProvider.export.ingredientExport;
      final filePath = await exportService.exportIngredientsToJson();

      if (mounted) {
        SnackbarService.showSuccess(
          context,
          'Ingredients exported successfully!\nFile: $filePath',
        );

        // Copy file path to clipboard for easy access
        await Clipboard.setData(ClipboardData(text: filePath));

        // Show additional info
        _showExportSuccessDialog(filePath, 'Ingredients');
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Failed to export ingredients: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExportingIngredients = false;
        });
      }
    }
  }

  Future<void> _backupDatabase() async {
    if (_isBackingUp) return;

    setState(() {
      _isBackingUp = true;
    });

    try {
      final backupService = ServiceProvider.database.backup;
      final backupPath = await backupService.backupDatabase();

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarService.showSuccess(
          context,
          l10n.backupSuccess,
        );

        // Show detailed success dialog
        _showBackupSuccessDialog(backupPath);
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        // Check if user cancelled
        if (e.message.contains('cancelled')) {
          SnackbarService.showSuccess(
            context,
            l10n.backupCancelled,
          );
        } else {
          SnackbarService.showError(
            context,
            '${l10n.backupFailed}: ${e.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        SnackbarService.showError(
          context,
          '${l10n.backupFailed}: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _restoreDatabase() async {
    if (_isRestoring) return;

    final l10n = AppLocalizations.of(context)!;

    // Get backup file path from user
    final filePathController = TextEditingController(
        text: '/sdcard/Download/'); // Pre-fill with Downloads directory
    final backupFilePath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.selectBackupFile),
        content: TextField(
          controller: filePathController,
          decoration: InputDecoration(
            labelText: l10n.backupFilePath,
            hintText: '/sdcard/Download/gastrobrain_backup_2024-12-04_120000.json',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(filePathController.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (backupFilePath == null || backupFilePath.trim().isEmpty) {
      return; // User cancelled or provided empty path
    }

    // Show warning dialog before proceeding
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreWarningTitle),
        content: Text(l10n.restoreWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.buttonContinue),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isRestoring = true;
    });

    try {
      final backupService = ServiceProvider.database.backup;
      await backupService.restoreDatabase(backupFilePath);

      if (mounted) {
        SnackbarService.showSuccess(
          context,
          l10n.restoreSuccess,
        );

        // Show success dialog
        _showRestoreSuccessDialog();
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        // Check if user cancelled
        if (e.message.contains('cancelled')) {
          SnackbarService.showSuccess(
            context,
            l10n.restoreCancelled,
          );
        } else {
          SnackbarService.showError(
            context,
            '${l10n.restoreFailed}: ${e.message}',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          '${l10n.restoreFailed}: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRestoring = false;
        });
      }
    }
  }

  void _showExportSuccessDialog(String filePath, [String type = 'Recipe']) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$type data has been exported to JSON format.'),
            const SizedBox(height: 16),
            const Text('📁 Saved to Downloads folder',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Full path:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(
              filePath,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            const SizedBox(height: 16),
            const Text('📋 File path copied to clipboard'),
            const SizedBox(height: 8),
            const Text(
              'You can find this file in your device\'s Downloads folder or file manager.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBackupSuccessDialog(String filePath) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupSuccess),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.backupSuccessDetails(filePath)),
            const SizedBox(height: 16),
            const Text('📋 File path copied to clipboard'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // Copy file path to clipboard
    Clipboard.setData(ClipboardData(text: filePath));
  }

  void _showRestoreSuccessDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.restoreSuccess),
        content: Text(l10n.restoreSuccessMessage),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Note: In a real app, you might want to restart or refresh the app state here
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _importRecipes() async {
    if (_isImportingRecipes) return;

    final l10n = AppLocalizations.of(context)!;

    // Get JSON file path from user
    final filePathController = TextEditingController(
        text: 'assets/recipe_export_1762460315862.json'); // Pre-fill with bundled asset
    final jsonFilePath = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Recipe JSON File'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: filePathController,
              decoration: const InputDecoration(
                labelText: 'JSON File Path',
                hintText: 'assets/recipe_export_1762460315862.json',
                helperText: 'Asset path or file system path',
              ),
              autofocus: true,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text(
              'You can use an asset path (e.g., assets/file.json) or a file system path (e.g., /sdcard/Download/file.json)',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(filePathController.text),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );

    if (jsonFilePath == null || jsonFilePath.trim().isEmpty) {
      return; // User cancelled or provided empty path
    }

    // Show warning dialog before proceeding
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Warning: Data Replacement'),
        content: const Text(
          'This will REPLACE all existing recipes and ingredients with data from the JSON file.\n\n'
          'Meal plans and cooking history will be preserved.\n\n'
          'This operation cannot be undone. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(l10n.buttonContinue),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isImportingRecipes = true;
    });

    try {
      final importService = ServiceProvider.export.recipeImport;
      final result = await importService.importRecipesFromJson(jsonFilePath);

      if (mounted) {
        if (result.hasErrors) {
          // Show success with warnings
          _showImportResultDialog(result, hasErrors: true);
        } else {
          // Show success
          _showImportResultDialog(result);
        }

        SnackbarService.showSuccess(
          context,
          'Import complete! ${result.recipesImported} recipes, ${result.ingredientsImported} ingredients',
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Import failed: ${e.message}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Import failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isImportingRecipes = false;
        });
      }
    }
  }

  void _showImportResultDialog(dynamic result, {bool hasErrors = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(hasErrors ? 'Import Completed with Errors' : 'Import Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!hasErrors)
              const Text('All recipes and ingredients have been imported successfully!'),
            if (hasErrors)
              const Text('Import completed but some errors occurred.'),
            const SizedBox(height: 16),
            const Text('📊 Summary:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Recipes imported: ${result.recipesImported}'),
            Text('• Ingredients imported: ${result.ingredientsImported}'),
            if (hasErrors) Text('• Errors: ${result.errors.length}'),
            if (hasErrors && result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('❌ Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    result.errors.join('\n'),
                    style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Simple section header - no over-engineering
  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.toolsScreenTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.toolsScreenSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),

            // Recipe Management Section
            _buildSectionHeader(l10n.recipeManagement, Icons.restaurant_menu),

            // Bulk Recipe Update
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.bulkRecipeUpdate,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.bulkRecipeUpdateDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushNamed('/bulk-recipe-update');
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Open Bulk Update'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Data Management Section
            _buildSectionHeader(l10n.dataManagement, Icons.storage),

            // Database Backup
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.backup,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.databaseBackup,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.backupDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isBackingUp ? null : _backupDatabase,
                        icon: _isBackingUp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.backup),
                        label: Text(_isBackingUp ? l10n.backingUp : l10n.backupAllData),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.restoreDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isRestoring ? null : _restoreDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.errorContainer,
                          foregroundColor: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                        icon: _isRestoring
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.restore),
                        label: Text(_isRestoring ? l10n.restoring : l10n.restoreFromBackup),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(l10n.importRecipesDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isImportingRecipes ? null : _importRecipes,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                        icon: _isImportingRecipes
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.file_upload),
                        label: Text(_isImportingRecipes ? 'Importing...' : l10n.importRecipes),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Recipe Export
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.file_download,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.exportRecipes,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.exportRecipesDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExportingRecipes ? null : _exportRecipes,
                        icon: _isExportingRecipes
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(_isExportingRecipes ? 'Exporting...' : l10n.exportRecipes),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredient Export
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.local_grocery_store,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          l10n.exportIngredients,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.exportIngredientsDescription),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExportingIngredients ? null : _exportIngredients,
                        icon: _isExportingIngredients
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(_isExportingIngredients ? 'Exporting...' : l10n.exportIngredients),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Section
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Export Information',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Recipe Export:\n'
                      '• Complete ingredient data (quantities, units, categories)\n'
                      '• Current ingredients show existing recipe compositions\n'
                      '• Enhanced ingredients array ready for external editing\n\n'
                      'Ingredient Export:\n'
                      '• All ingredients with categories, units, protein types\n'
                      '• Master ingredient list for external management\n'
                      '• Useful for ingredient database maintenance\n\n'
                      'Backup & Restore:\n'
                      '• Complete database backup to Downloads folder\n'
                      '• Restore from previous backups\n'
                      '• Import recipes and ingredients from JSON\n\n'
                      'General:\n'
                      '• Files saved to Downloads folder with timestamp\n'
                      '• Use exported data with import utilities',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
