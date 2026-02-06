import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';

class RecipeInstructionsViewScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeInstructionsViewScreen({super.key, required this.recipe});

  @override
  State<RecipeInstructionsViewScreen> createState() =>
      _RecipeInstructionsViewScreenState();
}

class _RecipeInstructionsViewScreenState
    extends State<RecipeInstructionsViewScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late String _instructions;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _instructions = widget.recipe.instructions;
  }

  Future<void> _editInstructions() async {
    final TextEditingController controller =
        TextEditingController(text: _instructions);

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.instructions),
        content: SingleChildScrollView(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.enterInstructions,
              border: const OutlineInputBorder(),
            ),
            maxLines: null,
            minLines: 10,
            keyboardType: TextInputType.multiline,
            autofocus: true,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );

    // Dispose the controller after the dialog animation completes
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.dispose();
      });
    }

    if (result != null) {
      await _saveInstructions(result);
    }
  }

  Future<void> _saveInstructions(String newInstructions) async {
    try {
      final updatedRecipe = Recipe(
        id: widget.recipe.id,
        name: widget.recipe.name,
        desiredFrequency: widget.recipe.desiredFrequency,
        notes: widget.recipe.notes,
        instructions: newInstructions,
        createdAt: widget.recipe.createdAt,
        difficulty: widget.recipe.difficulty,
        prepTimeMinutes: widget.recipe.prepTimeMinutes,
        cookTimeMinutes: widget.recipe.cookTimeMinutes,
        rating: widget.recipe.rating,
        category: widget.recipe.category,
      );

      await _dbHelper.updateRecipe(updatedRecipe);

      if (mounted) {
        setState(() {
          _instructions = newInstructions;
          // Mark that changes were made
          _hasChanges = true;
        });
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.instructionsUpdatedSuccessfully,
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        SnackbarService.showError(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.unexpectedError,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasInstructions = _instructions.isNotEmpty;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _hasChanges) {
          // Return true to indicate changes were made
          // This is handled by manually popping with the result
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.recipe.name),
          leading: BackButton(
            onPressed: () {
              Navigator.pop(context, _hasChanges);
            },
          ),
        ),
        body: hasInstructions ? _buildInstructionsView() : _buildEmptyState(),
        floatingActionButton: FloatingActionButton(
          onPressed: _editInstructions,
          tooltip: hasInstructions
              ? AppLocalizations.of(context)!.editInstructions
              : AppLocalizations.of(context)!.addInstructions,
          child: Icon(hasInstructions ? Icons.edit : Icons.add),
        ),
      ),
    );
  }

  Widget _buildInstructionsView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.instructions,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _instructions,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context)!.noInstructionsAvailable,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _editInstructions,
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.addInstructions),
            ),
          ],
        ),
      ),
    );
  }
}
