import 'package:flutter/material.dart';
import '../models/recipe.dart';
import '../models/frequency_type.dart';
import '../models/tag.dart';
import '../models/tag_type.dart';
import '../core/di/service_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/validators/entity_validator.dart';
import '../core/repositories/tag_repository.dart';
import '../core/services/tag_duplicate_checker.dart';
import '../l10n/app_localizations.dart';
import '../widgets/servings_stepper.dart';
import '../widgets/tag_picker_widget.dart';

class EditRecipeScreen extends StatefulWidget {
  final Recipe recipe;

  const EditRecipeScreen({super.key, required this.recipe});

  @override
  State<EditRecipeScreen> createState() => _EditRecipeScreenState();
}

class _EditRecipeScreenState extends State<EditRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _notesController;
  late TextEditingController _storyController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _marinatingTimeController;
  late int _servings;
  late FrequencyType _selectedFrequency;
  late int _difficulty;
  late int _rating;
  bool _isSaving = false;

  List<TagType> _tagTypes = [];
  Map<String, List<Tag>> _tagsByType = {};
  List<String> _selectedTagIds = [];
  late TagRepository _tagRepo;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.recipe.name);
    _notesController = TextEditingController(text: widget.recipe.notes);
    _storyController = TextEditingController(text: widget.recipe.story);
    _prepTimeController = TextEditingController(text: widget.recipe.prepTimeMinutes.toString());
    _cookTimeController = TextEditingController(text: widget.recipe.cookTimeMinutes.toString());
    _marinatingTimeController = TextEditingController(text: widget.recipe.marinatingTimeMinutes.toString());
    _servings = widget.recipe.servings;
    _selectedFrequency = widget.recipe.desiredFrequency;
    _difficulty = widget.recipe.difficulty;
    _rating = widget.recipe.rating;
    _tagRepo = TagRepository(ServiceProvider.database.helper);
    _loadTagData();
  }

  Future<void> _loadTagData() async {
    try {
      final all = await _tagRepo.getAllTagTypes();
      final types = all.toList();
      final byType = <String, List<Tag>>{};
      for (final t in types) {
        byType[t.id] = await _tagRepo.getTagsByType(t.id);
      }
      final existing = await _tagRepo.getTagsForRecipe(widget.recipe.id);
      if (mounted) {
        setState(() {
          _tagTypes = types;
          _tagsByType = byType;
          _selectedTagIds = existing.map((t) => t.id).toList();
        });
      }
    } catch (_) {}
  }

  Future<Tag?> _onCreateTag(String name, String typeId) async {
    try {
      final existing = _tagsByType[typeId] ?? [];
      if (TagDuplicateChecker(existing).check(name).isExact) return null;
      final tag = await _tagRepo.createTag(name, typeId);
      if (mounted) {
        setState(() => _tagsByType = {..._tagsByType, typeId: [...existing, tag]});
      }
      return tag;
    } catch (_) { return null; }
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

  Widget _buildTimeField(String label, TextEditingController controller,
      {Key? key}) {
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

  void _showErrorSnackBar(String message) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3)));

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Validate recipe data
      final servings = _servings;

      EntityValidator.validateRecipe(
        id: widget.recipe.id,
        name: _nameController.text,
        ingredients: [],
        instructions: [],
        servings: servings,
      );

      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);
      final marinatingTime = int.tryParse(_marinatingTimeController.text);

      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');
      EntityValidator.validateTime(marinatingTime?.toDouble(), 'Marinating');

      final updatedRecipe = Recipe(
        id: widget.recipe.id,
        name: _nameController.text,
        desiredFrequency: _selectedFrequency,
        notes: _notesController.text,
        story: _storyController.text,
        instructions: widget.recipe.instructions,
        createdAt: widget.recipe.createdAt,
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        marinatingTimeMinutes: marinatingTime ?? 0,
        rating: _rating,
        servings: servings,
      );

      final dbHelper = ServiceProvider.database.helper;
      await dbHelper.updateRecipe(updatedRecipe);
      await _tagRepo.setTagsForRecipe(widget.recipe.id, _selectedTagIds);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      _showErrorSnackBar(e.message);
    } on DuplicateException catch (e) {
      _showErrorSnackBar(e.message);
    } on NotFoundException catch (e) {
      _showErrorSnackBar(e.message);
    } on GastrobrainException catch (e) {
      _showErrorSnackBar('${AppLocalizations.of(context)!.errorUpdatingRecipe} ${e.message}');
    } catch (e) {
      _showErrorSnackBar(AppLocalizations.of(context)!.unexpectedError);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    _storyController.dispose();
    _prepTimeController.dispose();
    _cookTimeController.dispose();
    _marinatingTimeController.dispose();
    super.dispose();
  }

  List<Widget> _buildFormFields(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      TextFormField(
        key: const Key('edit_recipe_name_field'),
        controller: _nameController,
        decoration: InputDecoration(labelText: l10n.recipeName),
        validator: (value) {
          if (value == null || value.isEmpty) return l10n.pleaseEnterRecipeName;
          return null;
        },
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<FrequencyType>(
        key: const Key('edit_recipe_frequency_field'),
        initialValue: _selectedFrequency,
        decoration: InputDecoration(labelText: l10n.desiredFrequency),
        items: FrequencyType.values
            .map((f) => DropdownMenuItem(
                value: f, child: Text(f.getLocalizedDisplayName(context))))
            .toList(),
        onChanged: (v) { if (v != null) setState(() => _selectedFrequency = v); },
      ),
      const SizedBox(height: 16),
      _buildDifficultyField(l10n.difficultyLevel, _difficulty,
          (v) => setState(() => _difficulty = v)),
      const SizedBox(height: 16),
      _buildTimeField(l10n.preparationTime, _prepTimeController,
          key: const Key('edit_recipe_prep_time_field')),
      const SizedBox(height: 16),
      _buildTimeField(l10n.cookingTime, _cookTimeController,
          key: const Key('edit_recipe_cook_time_field')),
      const SizedBox(height: 16),
      _buildTimeField(l10n.marinatingTime, _marinatingTimeController,
          key: const Key('edit_recipe_marinating_time_field')),
      const SizedBox(height: 16),
      ServingsStepper(
        key: const Key('edit_recipe_servings_stepper'),
        value: _servings,
        onChanged: (v) => setState(() => _servings = v),
      ),
      const SizedBox(height: 16),
      _buildRatingField(l10n.rating, _rating,
          (v) => setState(() => _rating = v)),
      const SizedBox(height: 16),
      TextFormField(
        key: const Key('edit_recipe_notes_field'),
        controller: _notesController,
        decoration: InputDecoration(labelText: l10n.notes),
        maxLines: 3,
      ),
      const SizedBox(height: 16),
      TextFormField(
        key: const Key('edit_recipe_story_field'),
        controller: _storyController,
        decoration: InputDecoration(
          labelText: l10n.recipeStoryLabel,
          hintText: l10n.recipeStoryHint,
        ),
        maxLines: 5,
      ),
      const SizedBox(height: 16),
      TagPickerWidget(
        key: const Key('edit_recipe_tag_picker'),
        tagTypes: _tagTypes,
        tagsByType: _tagsByType,
        selectedTagIds: _selectedTagIds,
        onChanged: (ids) => setState(() => _selectedTagIds = ids),
        onCreateTag: _onCreateTag,
      ),
      const SizedBox(height: 24),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSaving ? null : _saveRecipe,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: _isSaving
                ? const CircularProgressIndicator()
                : Text(l10n.saveChanges),
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.editRecipe),
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
