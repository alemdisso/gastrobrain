import 'package:flutter/material.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../models/recipe.dart';
import '../models/ingredient.dart';
import '../models/recipe_ingredient.dart';
import '../models/frequency_type.dart';
import '../models/recipe_category.dart';
import '../models/measurement_unit.dart';
import '../database/database_helper.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/di/service_provider.dart';
import '../utils/id_generator.dart';
import '../core/services/snackbar_service.dart';
import '../l10n/app_localizations.dart';
import '../utils/quantity_formatter.dart';
import '../widgets/servings_stepper.dart';

class AddRecipeScreen extends StatefulWidget {
  final DatabaseHelper? databaseHelper;

  const AddRecipeScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  late DatabaseHelper _dbHelper;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _prepTimeController = TextEditingController();
  final _cookTimeController = TextEditingController();
  final _marinatingTimeController = TextEditingController();
  int _servings = 4;
  FrequencyType _selectedFrequency = FrequencyType.monthly;
  RecipeCategory _selectedCategory = RecipeCategory.uncategorized;
  int _difficulty = 1;
  int _rating = 0;
  bool _isSaving = false;
  final String _tempRecipeId = IdGenerator.generateId();
  final List<RecipeIngredient> _pendingIngredients = [];
  final Map<String, Ingredient> _ingredientDetails = {};

  final frequencies = FrequencyType.values;

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
  }

  Widget _buildRatingField(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) => IconButton(
            icon: Icon(i < value ? Icons.star : Icons.star_border,
                color: i < value ? Colors.amber : Colors.grey),
            onPressed: () => onChanged(i + 1),
          )),
        ),
      ],
    );
  }

  Widget _buildDifficultyField(String label, int value, Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (i) => IconButton(
            icon: Icon(i < value ? Icons.battery_full : Icons.battery_0_bar,
                color: i < value ? Colors.green : Colors.grey),
            onPressed: () => onChanged(i + 1),
          )),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller, {Key? key}) {
    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        suffixText: AppLocalizations.of(context)!.minutes,
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.isEmpty) return null;
        final minutes = int.tryParse(value);
        if (minutes == null || minutes < 0) {
          return AppLocalizations.of(context)!.pleaseEnterValidTime;
        }
        return null;
      },
    );
  }

  Widget _buildIngredientList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _pendingIngredients.length,
      itemBuilder: (context, index) {
        final ingredient = _pendingIngredients[index];
        return ListTile(
          title: ingredient.ingredientId != null
              ? FutureBuilder<Ingredient?>(
                  future: _getIngredientDetails(ingredient.ingredientId!),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final ingredientName = snapshot.data?.name ?? AppLocalizations.of(context)!.unknown;
                      if (ingredient.quantity == 0) return Text(ingredientName);
                      final unitString = ingredient.unitOverride ?? snapshot.data?.unit?.value ?? '';
                      final measurementUnit = MeasurementUnit.fromString(unitString);
                      final localizedUnit = measurementUnit?.getLocalizedQuantityName(context, ingredient.quantity) ?? unitString;
                      return Text('$ingredientName: ${QuantityFormatter.format(ingredient.quantity)} $localizedUnit');
                    }
                    return Text(AppLocalizations.of(context)!.loading);
                  },
                )
              : Text(() {
                  if (ingredient.quantity == 0) {
                    return ingredient.customName ?? '';
                  }
                  final customUnitString = ingredient.customUnit ?? '';
                  final measurementUnit = MeasurementUnit.fromString(customUnitString);
                  final localizedUnit = measurementUnit?.getLocalizedQuantityName(context, ingredient.quantity) ?? customUnitString;
                  return '${ingredient.customName}: ${QuantityFormatter.format(ingredient.quantity)} $localizedUnit';
                }()),
          subtitle: ingredient.notes != null ? Text(ingredient.notes!) : null,
          trailing: IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => setState(() => _pendingIngredients.removeAt(index)),
          ),
        );
      },
    );
  }

  Future<Ingredient?> _getIngredientDetails(String ingredientId) async {
    if (_ingredientDetails.containsKey(ingredientId)) {
      return _ingredientDetails[ingredientId];
    }
    try {
      final ingredients = await _dbHelper.getAllIngredients();
      for (final ingredient in ingredients) {
        _ingredientDetails[ingredient.id] = ingredient;
      }
      final ingredient = _ingredientDetails[ingredientId];
      if (ingredient == null) throw NotFoundException('Ingredient not found');
      return ingredient;
    } on GastrobrainException {
      rethrow;
    } catch (e) {
      throw GastrobrainException('Error loading ingredient details: $e');
    }
  }

  Future<void> _addIngredient() async {
    final tempRecipe = Recipe(
      id: _tempRecipeId,
      name: _nameController.text,
      desiredFrequency: _selectedFrequency,
      notes: _notesController.text,
      createdAt: DateTime.now(),
      difficulty: _difficulty,
      prepTimeMinutes: int.tryParse(_prepTimeController.text) ?? 0,
      cookTimeMinutes: int.tryParse(_cookTimeController.text) ?? 0,
      marinatingTimeMinutes: int.tryParse(_marinatingTimeController.text) ?? 0,
      rating: _rating,
      category: _selectedCategory,
      servings: _servings,
    );

    final result = await showDialog<RecipeIngredient>(
      context: context,
      builder: (context) => AddIngredientDialog(
        recipe: tempRecipe,
        databaseHelper: _dbHelper,
        onSave: (_) {},
      ),
    );

    if (result != null) setState(() => _pendingIngredients.add(result));
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    try {
      final servings = _servings;
      EntityValidator.validateRecipe(
        id: _tempRecipeId,
        name: _nameController.text,
        ingredients: _pendingIngredients.map((i) => i.toMap()).toList(),
        instructions: [],
        servings: servings,
      );

      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);
      final marinatingTime = int.tryParse(_marinatingTimeController.text);

      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');
      EntityValidator.validateTime(marinatingTime?.toDouble(), 'Marinating');

      final recipe = Recipe(
        id: _tempRecipeId,
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        marinatingTimeMinutes: marinatingTime ?? 0,
        rating: _rating,
        servings: servings,
      );

      await _dbHelper.insertRecipe(recipe);
      for (final ingredient in _pendingIngredients) {
        await _dbHelper.addIngredientToRecipe(ingredient);
      }

      if (mounted) Navigator.pop(context, true);
    } on ValidationException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on DuplicateException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context,
          '${AppLocalizations.of(context)!.errorSavingRecipe} ${e.message}');
    } catch (e) {
      if (mounted) SnackbarService.showError(context, AppLocalizations.of(context)!.unexpectedError);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _marinatingTimeController.dispose();
    super.dispose();
  }

  Widget _buildIngredientsCard(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l10n.ingredients,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.add),
                  onPressed: _addIngredient,
                ),
              ],
            ),
            if (_pendingIngredients.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(l10n.noIngredientsAdded,
                      style: const TextStyle(
                          color: Colors.grey, fontStyle: FontStyle.italic)),
                ),
              )
            else
              _buildIngredientList(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildFormFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      TextFormField(
        key: const Key('add_recipe_name_field'),
        controller: _nameController,
        decoration: InputDecoration(labelText: l10n.recipeName),
        validator: (value) =>
            (value == null || value.isEmpty) ? l10n.pleaseEnterRecipeName : null,
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<FrequencyType>(
        key: const Key('add_recipe_frequency_field'),
        initialValue: _selectedFrequency,
        decoration: InputDecoration(labelText: l10n.desiredFrequency),
        items: frequencies
            .map((f) => DropdownMenuItem(
                value: f, child: Text(f.getLocalizedDisplayName(context))))
            .toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedFrequency = v); },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<RecipeCategory>(
        key: const Key('add_recipe_category_field'),
        initialValue: _selectedCategory,
        decoration: InputDecoration(labelText: l10n.category),
        items: RecipeCategory.values
            .map((c) => DropdownMenuItem(
                value: c, child: Text(c.getLocalizedDisplayName(context))))
            .toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedCategory = v); },
      ),
      const SizedBox(height: 16),
      _buildDifficultyField(l10n.difficultyLevel, _difficulty,
          (v) => setState(() => _difficulty = v)),
      const SizedBox(height: 16),
      _buildTimeField(l10n.preparationTime, _prepTimeController,
          key: const Key('add_recipe_prep_time_field')),
      const SizedBox(height: 16),
      _buildTimeField(l10n.cookingTime, _cookTimeController,
          key: const Key('add_recipe_cook_time_field')),
      const SizedBox(height: 16),
      _buildTimeField(l10n.marinatingTime, _marinatingTimeController,
          key: const Key('add_recipe_marinating_time_field')),
      const SizedBox(height: 16),
      ServingsStepper(
        key: const Key('add_recipe_servings_stepper'),
        value: _servings,
        onChanged: (v) => setState(() => _servings = v),
      ),
      const SizedBox(height: 16),
      _buildRatingField(l10n.rating, _rating, (v) => setState(() => _rating = v)),
      const SizedBox(height: 16),
      TextFormField(
        key: const Key('add_recipe_notes_field'),
        controller: _notesController,
        decoration: InputDecoration(labelText: l10n.notes),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      _buildIngredientsCard(context),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRecipe,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _isSaving
                ? const CircularProgressIndicator()
                : Text(l10n.saveRecipe),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.addNewRecipe),
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildFormFields(context),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
