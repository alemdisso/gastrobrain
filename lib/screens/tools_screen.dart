import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/di/service_provider.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/ingredient_translation_service.dart';

/// Temporary tools screen for development utilities
class ToolsScreen extends StatefulWidget {
  const ToolsScreen({super.key});

  @override
  State<ToolsScreen> createState() => _ToolsScreenState();
}

class _ToolsScreenState extends State<ToolsScreen> {
  bool _isExportingRecipes = false;
  bool _isExportingIngredients = false;
  bool _isTranslatingIngredients = false;

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

  Future<void> _translateIngredients() async {
    if (_isTranslatingIngredients) return;

    setState(() {
      _isTranslatingIngredients = true;
    });

    try {
      final translationService = IngredientTranslationService();
      final result = await translationService.translateIngredients();

      if (mounted) {
        if (result.isSuccess) {
          SnackbarService.showSuccess(
            context,
            'Translation successful!\n${result.summary}',
          );

          // Show detailed success dialog
          _showTranslationSuccessDialog(result);
        } else {
          SnackbarService.showError(
            context,
            'Translation completed with errors!\n${result.summary}',
          );

          // Show error dialog with details
          _showTranslationErrorDialog(result);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          'Translation failed: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranslatingIngredients = false;
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

  void _showTranslationSuccessDialog(TranslationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All ingredients have been translated to Portuguese!'),
            const SizedBox(height: 16),
            const Text('📊 Summary:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Total processed: ${result.totalProcessed}'),
            Text('• Successfully updated: ${result.successCount}'),
            Text('• Errors: ${result.errorCount}'),
            const SizedBox(height: 16),
            const Text('🎉 Your ingredient database is now in Portuguese!'),
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

  void _showTranslationErrorDialog(TranslationResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Translation Completed with Errors'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Translation completed but some errors occurred.'),
            const SizedBox(height: 16),
            const Text('📊 Summary:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('• Total processed: ${result.totalProcessed}'),
            Text('• Successfully updated: ${result.successCount}'),
            Text('• Errors: ${result.errorCount}'),
            if (result.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('❌ Errors:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: SingleChildScrollView(
                  child: Text(
                    result.errors.join('\n'),
                    style:
                        const TextStyle(fontSize: 12, fontFamily: 'monospace'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development Tools',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Temporary tools for development and testing purposes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),

            // Recipe Export Section
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
                          'Recipe Data Export',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export all recipe data with current ingredients (quantities, units, categories) to JSON format for external enhancement.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isExportingRecipes ? null : _exportRecipes,
                        icon: _isExportingRecipes
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(_isExportingRecipes
                            ? 'Exporting...'
                            : 'Export Recipes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredient Export Section
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
                          'Ingredient Data Export',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Export all ingredient data including categories, units, protein types, and notes to JSON format for external management.',
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed:
                            _isExportingIngredients ? null : _exportIngredients,
                        icon: _isExportingIngredients
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.download),
                        label: Text(_isExportingIngredients
                            ? 'Exporting...'
                            : 'Export Ingredients'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ingredient Translation Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.translate,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ingredient Translation',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Translate all ingredients from English to Portuguese using the reviewed translation data. This will update ingredient names, categories, units, and protein types.',
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This will permanently update your ingredient database. Make sure you have a backup.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isTranslatingIngredients
                            ? null
                            : _translateIngredients,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        icon: _isTranslatingIngredients
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.translate),
                        label: Text(_isTranslatingIngredients
                            ? 'Translating...'
                            : 'Translate to Portuguese'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bulk Recipe Update Section
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
                          'Bulk Recipe Update',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Update existing recipes with ingredient data and cooking instructions. Efficiently add missing details to recipes.',
                    ),
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
                      'Ingredient Translation:\n'
                      '• Translates all ingredients from English to Portuguese\n'
                      '• Updates names, categories, units, and protein types\n'
                      '• Uses reviewed translation data (330+ ingredients)\n'
                      '• Permanent operation - creates backup first\n\n'
                      'General:\n'
                      '• Files saved to Downloads folder with timestamp\n'
                      '• Use exported data with import utilities\n'
                      '• Translation uses embedded CSV data for accuracy',
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
