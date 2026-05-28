import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:uuid/uuid.dart';
import '../core/di/service_provider.dart';
import '../core/errors/gastrobrain_exceptions.dart';
import '../core/repositories/tag_repository.dart';
import '../core/services/ingredient_matching_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/services/tag_duplicate_checker.dart';
import '../core/validators/entity_validator.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import '../models/frequency_type.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';
import '../models/recipe_ingredient.dart';
import '../models/tag.dart';
import '../models/tag_type.dart';
import '../utils/id_generator.dart';
import '../widgets/add_new_ingredient_dialog.dart';
import '../widgets/ingredient_parser/ingredient_parser_section.dart';
import '../widgets/recipe_editor/parsed_ingredient.dart';
import '../widgets/servings_stepper.dart';
import '../widgets/tag_picker_widget.dart';
import 'recipe_details_screen.dart';

/// Unified recipe creation and editing screen.
///
/// Pass [recipe] = null for create mode (phases 1 → 4 progressive flow).
/// Pass an existing [recipe] for edit mode (all sections visible immediately).
class RecipeFormScreen extends StatefulWidget {
  final Recipe? recipe;
  final DatabaseHelper? databaseHelper;

  const RecipeFormScreen({
    super.key,
    this.recipe,
    this.databaseHelper,
  });

  @override
  State<RecipeFormScreen> createState() => _RecipeFormScreenState();
}

class _RecipeFormScreenState extends State<RecipeFormScreen> {
  late DatabaseHelper _dbHelper;
  late TagRepository _tagRepo;

  bool get _isCreateMode => widget.recipe == null;

  // ── Phase 1 state ─────────────────────────────────────────────────────────
  final _phase1FormKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late FrequencyType _selectedFrequency;
  late int _servings;
  bool _isSavingPhase1 = false;
  bool _phase1Saved = false;
  Recipe? _savedRecipe; // set after Phase 1 save in create mode

  // ── Phase 4 state ─────────────────────────────────────────────────────────
  final IngredientMatchingService _matchingService = IngredientMatchingService();
  bool _isMatchingServiceReady = false;
  bool _isParserServiceReady = false;
  bool _isSavingIngredients = false;

  // ── Phase 2 state (timing & difficulty) ──────────────────────────────────
  final _phase2FormKey = GlobalKey<FormState>();
  bool _isSavingPhase2 = false;
  bool _phase2HasChanges = false;

  // ── Phase 3 state (tags & rating) ────────────────────────────────────────
  bool _isSavingPhase3 = false;
  bool _phase3HasChanges = false;

  // ── Phase 5 state (notes & story) ────────────────────────────────────────
  final _phase5FormKey = GlobalKey<FormState>();
  late TextEditingController _notesController;
  late TextEditingController _storyController;
  late TextEditingController _prepTimeController;
  late TextEditingController _cookTimeController;
  late TextEditingController _marinatingTimeController;
  late int _difficulty;
  late int _rating;
  bool _isStoryPreviewMode = false;
  bool _isSavingPhase5 = false;
  bool _phase5HasChanges = false;
  List<TagType> _tagTypes = [];
  Map<String, List<Tag>> _tagsByType = {};
  List<String> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _tagRepo = TagRepository(_dbHelper);

    final r = widget.recipe;
    _nameController = TextEditingController(text: r?.name ?? '')
      ..addListener(() => setState(() {}));
    _selectedFrequency = r?.desiredFrequency ?? FrequencyType.monthly;
    _servings = (r?.servings ?? 0) > 0 ? r!.servings : 4;

    _notesController = TextEditingController(text: r?.notes ?? '');
    _storyController = TextEditingController(text: r?.story ?? '');
    _prepTimeController = TextEditingController(
        text: r != null && r.prepTimeMinutes > 0
            ? r.prepTimeMinutes.toString()
            : '');
    _cookTimeController = TextEditingController(
        text: r != null && r.cookTimeMinutes > 0
            ? r.cookTimeMinutes.toString()
            : '');
    _marinatingTimeController = TextEditingController(
        text: r != null && r.marinatingTimeMinutes > 0
            ? r.marinatingTimeMinutes.toString()
            : '');
    _difficulty = r?.difficulty ?? 1;
    _rating = r?.rating ?? 0;

    if (!_isCreateMode) {
      _loadTagData(r!.id);
      _loadAllIngredients();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isParserServiceReady && _isMatchingServiceReady && mounted) {
      final l10n = AppLocalizations.of(context);
      if (l10n != null) {
        ServiceProvider.ingredientParser
            .initialize(l10n, matchingService: _matchingService);
        setState(() => _isParserServiceReady = true);
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

  Future<void> _loadAllIngredients() async {
    try {
      final ingredients = await _dbHelper.getAllIngredients();
      _matchingService.initialize(ingredients);
      if (mounted) {
        setState(() => _isMatchingServiceReady = true);
        final l10n = AppLocalizations.of(context);
        if (l10n != null && !_isParserServiceReady) {
          ServiceProvider.ingredientParser
              .initialize(l10n, matchingService: _matchingService);
          setState(() => _isParserServiceReady = true);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isMatchingServiceReady = false);
    }
  }

  Future<void> _loadTagData(String recipeId) async {
    try {
      final all = await _tagRepo.getAllTagTypes();
      final types = all.toList();
      final byType = <String, List<Tag>>{};
      for (final t in types) {
        byType[t.id] = await _tagRepo.getTagsByType(t.id);
      }
      final existing = await _tagRepo.getTagsForRecipe(recipeId);
      if (mounted) {
        setState(() {
          _tagTypes = types;
          _tagsByType = byType;
          _selectedTagIds = existing.map((t) => t.id).toList();
        });
      }
    } catch (e) {
      debugPrint('Failed to load tag data: $e');
    }
  }

  Future<Tag?> _onCreateTag(String name, String typeId) async {
    try {
      final existing = _tagsByType[typeId] ?? [];
      if (TagDuplicateChecker(existing).check(name).isExact) return null;
      final tag = await _tagRepo.createTag(name, typeId);
      if (mounted) {
        setState(
            () => _tagsByType = {..._tagsByType, typeId: [...existing, tag]});
      }
      return tag;
    } catch (_) {
      return null;
    }
  }

  // ── Phase 1: save ─────────────────────────────────────────────────────────

  Future<void> _savePhase1() async {
    if (!_phase1FormKey.currentState!.validate()) return;
    setState(() => _isSavingPhase1 = true);

    try {
      final recipe = widget.recipe;
      if (_isCreateMode) {
        final newId = IdGenerator.generateId();
        EntityValidator.validateRecipe(
          id: newId,
          name: _nameController.text,
          ingredients: [],
          instructions: [],
          servings: _servings,
        );
        final newRecipe = Recipe(
          id: newId,
          name: _nameController.text,
          desiredFrequency: _selectedFrequency,
          createdAt: DateTime.now(),
          servings: _servings,
          difficulty: 1,
        );
        await _dbHelper.insertRecipe(newRecipe);
        await _loadAllIngredients();
        _loadTagData(newId);
        if (mounted) {
          setState(() {
            _savedRecipe = newRecipe;
            _phase1Saved = true;
          });
        }
      } else {
        EntityValidator.validateRecipe(
          id: recipe!.id,
          name: _nameController.text,
          ingredients: [],
          instructions: [],
          servings: _servings,
        );
        final updated = recipe.copyWith(
          name: _nameController.text,
          desiredFrequency: _selectedFrequency,
          servings: _servings,
        );
        await _dbHelper.updateRecipe(updated);
        if (mounted) {
          SnackbarService.showSuccess(
              context, AppLocalizations.of(context)!.saveChanges);
          Navigator.pop(context, true);
        }
      }
    } on ValidationException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on DuplicateException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isSavingPhase1 = false);
    }
  }

  // ── Phase 2: timing & difficulty ─────────────────────────────────────────

  Future<void> _savePhase2() async {
    if (!_phase2FormKey.currentState!.validate()) return;
    final recipe = _activeRecipe;
    if (recipe == null) return;
    setState(() => _isSavingPhase2 = true);

    try {
      final prepTime = int.tryParse(_prepTimeController.text);
      final cookTime = int.tryParse(_cookTimeController.text);
      final marinatingTime = int.tryParse(_marinatingTimeController.text);
      EntityValidator.validateTime(prepTime?.toDouble(), 'Preparation');
      EntityValidator.validateTime(cookTime?.toDouble(), 'Cooking');
      EntityValidator.validateTime(marinatingTime?.toDouble(), 'Marinating');

      final updated = recipe.copyWith(
        difficulty: _difficulty,
        prepTimeMinutes: prepTime ?? 0,
        cookTimeMinutes: cookTime ?? 0,
        marinatingTimeMinutes: marinatingTime ?? 0,
      );
      await _dbHelper.updateRecipe(updated);
      if (mounted) {
        setState(() => _phase2HasChanges = false);
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.saveChanges);
        if (!_isCreateMode) Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isSavingPhase2 = false);
    }
  }

  // ── Phase 3: tags & rating ───────────────────────────────────────────────

  Future<void> _savePhase3() async {
    final recipe = _activeRecipe;
    if (recipe == null) return;
    setState(() => _isSavingPhase3 = true);

    try {
      final updated = recipe.copyWith(rating: _rating);
      await _dbHelper.updateRecipe(updated);
      await _tagRepo.setTagsForRecipe(recipe.id, _selectedTagIds);
      if (mounted) {
        setState(() => _phase3HasChanges = false);
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.saveChanges);
        if (!_isCreateMode) Navigator.pop(context, true);
      }
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isSavingPhase3 = false);
    }
  }

  // ── Phase 4: ingredients ──────────────────────────────────────────────────

  Recipe? get _activeRecipe => _isCreateMode ? _savedRecipe : widget.recipe;

  Future<bool> _saveIngredients(List<ParsedIngredient> confirmed) async {
    final recipe = _activeRecipe;
    if (recipe == null) return false;

    setState(() => _isSavingIngredients = true);
    try {
      const uuid = Uuid();
      final existing = await _dbHelper.getRecipeIngredients(recipe.id);
      final existingById = <String, Map<String, dynamic>>{
        for (final e in existing)
          if (e['ingredient_id'] != null) e['ingredient_id'] as String: e,
      };

      for (final parsed in confirmed) {
        if (parsed.name.trim().isEmpty) continue;
        if (parsed.isNewIngredient) {
          await _dbHelper.insertIngredient(parsed.newIngredientToCreate!);
        }
        final ingredientId = parsed.selectedMatch?.ingredient.id ??
            parsed.newIngredientToCreate?.id;
        if (ingredientId == null) continue;

        if (existingById.containsKey(ingredientId)) {
          final ri = RecipeIngredient(
            id: existingById[ingredientId]!['recipe_ingredient_id'] as String,
            recipeId: recipe.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          );
          await _dbHelper.updateRecipeIngredient(ri);
        } else {
          await _dbHelper.addIngredientToRecipe(RecipeIngredient(
            id: uuid.v4(),
            recipeId: recipe.id,
            ingredientId: ingredientId,
            quantity: parsed.quantity,
            quantityMax: parsed.quantityMax,
            notes: parsed.notes,
            unitOverride: parsed.unit,
          ));
        }
      }
      return true;
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
      return false;
    } finally {
      if (mounted) setState(() => _isSavingIngredients = false);
    }
  }

  Future<Ingredient?> _showCreateIngredientDialog(
      ParsedIngredient parsed) async {
    final prefilled = Ingredient(
      id: IdGenerator.generateId(),
      name:
          parsed.originalName.isNotEmpty ? parsed.originalName : parsed.name,
      category: parsed.category,
      unit: null,
      notes: parsed.notes,
    );
    return showDialog<Ingredient>(
      context: context,
      builder: (_) => AddNewIngredientDialog(ingredient: prefilled),
    );
  }

  void _navigateToRecipeDetails() {
    final recipe = _activeRecipe;
    if (recipe == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (_) =>
              RecipeDetailsScreen(recipe: recipe, databaseHelper: _dbHelper)),
    );
  }

  // ── More details: save ────────────────────────────────────────────────────

  Future<void> _savePhase5() async {
    if (!_phase5FormKey.currentState!.validate()) return;
    final recipe = _activeRecipe;
    if (recipe == null) return;
    setState(() => _isSavingPhase5 = true);

    try {
      final updated = recipe.copyWith(
        notes: _notesController.text,
        story: _storyController.text,
      );
      await _dbHelper.updateRecipe(updated);
      if (mounted) {
        setState(() => _phase5HasChanges = false);
        SnackbarService.showSuccess(
            context, AppLocalizations.of(context)!.saveChanges);
        if (!_isCreateMode) Navigator.pop(context, true);
      }
    } on ValidationException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } on GastrobrainException catch (e) {
      if (mounted) SnackbarService.showError(context, e.message);
    } catch (_) {
      if (mounted) {
        SnackbarService.showError(
            context, AppLocalizations.of(context)!.unexpectedError);
      }
    } finally {
      if (mounted) setState(() => _isSavingPhase5 = false);
    }
  }

  Future<void> _showDiscardDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.discardChanges),
        content: Text(l10n.discardChangesBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.of(context).pop();
  }

  // ── Build helpers ─────────────────────────────────────────────────────────

  Widget _buildSaveButton({
    Key? key,
    required String label,
    required bool isSaving,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        key: key,
        onPressed: isSaving ? null : onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(label),
        ),
      ),
    );
  }

  Widget _buildRatingField(
      String label, int value, void Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              icon: Icon(i < value ? Icons.star : Icons.star_border,
                  color: i < value ? Colors.amber : Colors.grey),
              onPressed: () => onChanged(i + 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultyField(
      String label, int value, void Function(int) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => IconButton(
              icon: Icon(i < value ? Icons.battery_full : Icons.battery_0_bar,
                  color: i < value ? Colors.green : Colors.grey),
              onPressed: () => onChanged(i + 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeField(String label, TextEditingController controller,
      {Key? key}) {
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      key: key,
      controller: controller,
      decoration: InputDecoration(
          labelText: label, suffixText: l10n.minutes),
      keyboardType: TextInputType.number,
      validator: (v) {
        if (v == null || v.isEmpty) return null;
        final m = int.tryParse(v);
        if (m == null || m < 0) return l10n.pleaseEnterValidTime;
        return null;
      },
    );
  }

  // ── Phase 3 section ───────────────────────────────────────────────────────

  Widget _buildPhase3Section() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRatingField(l10n.rating, _rating, (v) => setState(() {
              _rating = v;
              _phase3HasChanges = true;
            })),
        const SizedBox(height: 16),
        TagPickerWidget(
          key: const Key('recipe_form_tag_picker'),
          tagTypes: _tagTypes,
          tagsByType: _tagsByType,
          selectedTagIds: _selectedTagIds,
          onChanged: (ids) => setState(() {
            _selectedTagIds = ids;
            _phase3HasChanges = true;
          }),
          onCreateTag: _onCreateTag,
        ),
        const SizedBox(height: 24),
        _buildSaveButton(
          key: const Key('recipe_form_phase3_save_button'),
          label: l10n.saveChanges,
          isSaving: _isSavingPhase3,
          onPressed: _savePhase3,
        ),
      ],
    );
  }

  // ── Phase 2 section ───────────────────────────────────────────────────────

  Widget _buildPhase2Section() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _phase2FormKey,
      onChanged: () => setState(() => _phase2HasChanges = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDifficultyField(l10n.difficultyLevel, _difficulty,
              (v) => setState(() {
                    _difficulty = v;
                    _phase2HasChanges = true;
                  })),
          const SizedBox(height: 16),
          _buildTimeField(l10n.preparationTime, _prepTimeController,
              key: const Key('recipe_form_prep_time_field')),
          const SizedBox(height: 16),
          _buildTimeField(l10n.cookingTime, _cookTimeController,
              key: const Key('recipe_form_cook_time_field')),
          const SizedBox(height: 16),
          _buildTimeField(l10n.marinatingTime, _marinatingTimeController,
              key: const Key('recipe_form_marinating_time_field')),
          const SizedBox(height: 24),
          _buildSaveButton(
            key: const Key('recipe_form_phase2_save_button'),
            label: l10n.saveChanges,
            isSaving: _isSavingPhase2,
            onPressed: _savePhase2,
          ),
        ],
      ),
    );
  }

  // ── Phase 1 section ───────────────────────────────────────────────────────

  Widget _buildPhase1CreateSummary() {
    final recipe = _savedRecipe!;
    final l10n = AppLocalizations.of(context)!;
    final servingsLabel =
        '${recipe.servings} ${l10n.servings.toLowerCase()}';
    return Card(
      child: ListTile(
        leading: Icon(Icons.check_circle,
            color: Theme.of(context).colorScheme.primary),
        title: Text(recipe.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${recipe.desiredFrequency.getLocalizedDisplayName(context)}  ·  $servingsLabel'),
        trailing: IconButton(
          tooltip: l10n.editBasics,
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => setState(() => _phase1Saved = false),
        ),
      ),
    );
  }

  Widget _buildPhase1Form() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _phase1FormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('recipe_form_name_field'),
            controller: _nameController,
            autofocus: _isCreateMode,
            decoration: InputDecoration(labelText: l10n.recipeName),
            validator: (v) =>
                (v == null || v.isEmpty) ? l10n.pleaseEnterRecipeName : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FrequencyType>(
            key: const Key('recipe_form_frequency_field'),
            initialValue: _selectedFrequency,
            decoration: InputDecoration(labelText: l10n.desiredFrequency),
            items: FrequencyType.values
                .map((f) => DropdownMenuItem(
                    value: f,
                    child: Text(f.getLocalizedDisplayName(context))))
                .toList(),
            onChanged: (v) {
              if (v != null) setState(() => _selectedFrequency = v);
            },
          ),
          const SizedBox(height: 16),
          ServingsStepper(
            key: const Key('recipe_form_servings_stepper'),
            value: _servings,
            onChanged: (v) => setState(() => _servings = v),
          ),
          const SizedBox(height: 24),
          _buildSaveButton(
            label: _isCreateMode ? l10n.saveRecipe : l10n.saveChanges,
            isSaving: _isSavingPhase1,
            onPressed: _nameController.text.trim().isEmpty ? null : _savePhase1,
          ),
        ],
      ),
    );
  }

  // ── Phase 4 section ───────────────────────────────────────────────────────

  Widget _buildPhase4Section() {
    final l10n = AppLocalizations.of(context)!;
    final recipe = _activeRecipe;
    if (recipe == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            l10n.ingredients,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        IngredientParserSection(
          key: ValueKey(recipe.id),
          matchingService: _matchingService,
          isServicesReady: _isParserServiceReady,
          onIngredientsConfirmed: (list) async {
            final ok = await _saveIngredients(list);
            if (ok && mounted) {
              if (_isCreateMode) {
                SnackbarService.showSuccess(
                    context, AppLocalizations.of(context)!.saveChanges);
              } else {
                Navigator.pop(context, true);
              }
            }
            return ok;
          },
          onCreateNew: _showCreateIngredientDialog,
        ),
        if (_isCreateMode) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _isSavingIngredients ? null : _navigateToRecipeDetails,
              child: Text(l10n.skipForNow),
            ),
          ),
        ],
      ],
    );
  }

  // ── More details section (edit mode) ─────────────────────────────────────

  Widget _buildPhase5Section() {
    final l10n = AppLocalizations.of(context)!;
    return Form(
      key: _phase5FormKey,
      onChanged: () => setState(() => _phase5HasChanges = true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            key: const Key('recipe_form_notes_field'),
            controller: _notesController,
            decoration: InputDecoration(labelText: l10n.notes),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildStoryField(l10n),
          const SizedBox(height: 24),
          _buildSaveButton(
            key: const Key('recipe_form_phase5_save_button'),
            label: l10n.saveChanges,
            isSaving: _isSavingPhase5,
            onPressed: _savePhase5,
          ),
        ],
      ),
    );
  }

  Widget _buildStoryField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l10n.recipeStoryLabel,
                style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.edit_outlined)),
                ButtonSegment(
                    value: true, icon: Icon(Icons.visibility_outlined)),
              ],
              selected: {_isStoryPreviewMode},
              onSelectionChanged: (v) =>
                  setState(() => _isStoryPreviewMode = v.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity(
                    horizontal: VisualDensity.minimumDensity,
                    vertical: VisualDensity.minimumDensity),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isStoryPreviewMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border:
                  Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: _storyController.text.isEmpty
                ? Text(l10n.enterStory,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant,
                          fontStyle: FontStyle.italic,
                        ))
                : MarkdownBody(
                    data: _storyController.text,
                    shrinkWrap: true,
                    styleSheet:
                        MarkdownStyleSheet.fromTheme(Theme.of(context))
                            .copyWith(
                                p: const TextStyle(
                                    fontSize: 16, height: 1.5)),
                  ),
          )
        else
          TextFormField(
            key: const Key('recipe_form_story_field'),
            controller: _storyController,
            decoration: InputDecoration(
              hintText: l10n.recipeStoryHint,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
            maxLines: 5,
          ),
      ],
    );
  }

  // ── Body builders ─────────────────────────────────────────────────────────

  Widget _buildCreateBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_phase1Saved) ...[
            _buildPhase1Form(),
          ] else ...[
            _buildPhase1CreateSummary(),
            const SizedBox(height: 24),
            _buildPhase4Section(),
            const SizedBox(height: 12),
            _SectionExpansion(
              title: l10n.timingAndDifficulty,
              initiallyExpanded: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildPhase2Section(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionExpansion(
              title: l10n.tagsAndRating,
              initiallyExpanded: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildPhase3Section(),
              ),
            ),
            const SizedBox(height: 12),
            _SectionExpansion(
              title: l10n.notesAndStory,
              initiallyExpanded: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: _buildPhase5Section(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEditBody(AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phase 1 section
          _SectionExpansion(
            title: l10n.basics,
            initiallyExpanded: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildPhase1Form(),
            ),
          ),
          const SizedBox(height: 12),
          // Phase 4 section
          _SectionExpansion(
            title: l10n.ingredients,
            initiallyExpanded: true,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildPhase4Section(),
            ),
          ),
          const SizedBox(height: 12),
          // Phase 2 — timing & difficulty
          _SectionExpansion(
            title: l10n.timingAndDifficulty,
            initiallyExpanded: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildPhase2Section(),
            ),
          ),
          const SizedBox(height: 12),
          // Phase 3 — tags & rating
          _SectionExpansion(
            title: l10n.tagsAndRating,
            initiallyExpanded: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildPhase3Section(),
            ),
          ),
          const SizedBox(height: 12),
          // Phase 5 — notes & story
          _SectionExpansion(
            title: l10n.notesAndStory,
            initiallyExpanded: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: _buildPhase5Section(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final appBarTitle = _isCreateMode
        ? (_phase1Saved ? (_savedRecipe?.name ?? l10n.newRecipe) : l10n.newRecipe)
        : l10n.editRecipe;

    return PopScope(
      canPop: !(_phase5HasChanges || _phase2HasChanges || _phase3HasChanges),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop &&
            (_phase5HasChanges || _phase2HasChanges || _phase3HasChanges)) {
          _showDiscardDialog();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(appBarTitle)),
        body: SafeArea(
          top: false,
          bottom: true,
          child: _isCreateMode
              ? _buildCreateBody(l10n)
              : _buildEditBody(l10n),
        ),
      ),
    );
  }
}

// ── Private helpers ───────────────────────────────────────────────────────────

class _SectionExpansion extends StatefulWidget {
  final String title;
  final bool initiallyExpanded;
  final Widget child;

  const _SectionExpansion({
    required this.title,
    required this.initiallyExpanded,
    required this.child,
  });

  @override
  State<_SectionExpansion> createState() => _SectionExpansionState();
}

class _SectionExpansionState extends State<_SectionExpansion> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Icon(_expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: widget.child,
            ),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
