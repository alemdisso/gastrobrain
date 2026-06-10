import 'package:flutter/material.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe.dart';
import '../utils/id_generator.dart';
import 'recipe_details_screen.dart';

/// Minimal stub-creation screen — name only.
///
/// Saves a bare-bones recipe immediately on confirm and navigates to
/// [RecipeDetailsScreen], which becomes the editing hub for all sections.
class RecipeStubCreateScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;

  const RecipeStubCreateScreen({super.key, this.databaseHelper});

  @override
  State<RecipeStubCreateScreen> createState() => _RecipeStubCreateScreenState();
}

class _RecipeStubCreateScreenState extends State<RecipeStubCreateScreen> {
  late final DatabaseHelper _dbHelper;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? DatabaseHelper();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final recipe = Recipe(
        id: IdGenerator.generateId(),
        name: _nameController.text.trim(),
        createdAt: DateTime.now(),
      );
      await _dbHelper.insertRecipe(recipe);

      if (mounted) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RecipeDetailsScreen(recipe: recipe),
          ),
        );
      }
    } on GastrobrainException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.unexpectedError)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.newRecipe),
        leading: BackButton(onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          24, 24, 24,
          24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.recipeName,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.recipeNameRequired
                    : null,
                onFieldSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
