import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/frequency_type.dart';
import '../../models/recipe.dart';

/// Bottom sheet for editing all recipe metadata in one place:
/// name, servings, difficulty, prep/cook/marinating times,
/// desired frequency, notes, and story.
///
/// Returns an updated [Recipe] on save, or null on cancel.
class RecipeInfoEditSheet extends StatefulWidget {
  final Recipe recipe;

  const RecipeInfoEditSheet({super.key, required this.recipe});

  @override
  State<RecipeInfoEditSheet> createState() => _RecipeInfoEditSheetState();
}

class _RecipeInfoEditSheetState extends State<RecipeInfoEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _servingsCtrl;
  late final TextEditingController _prepCtrl;
  late final TextEditingController _cookCtrl;
  late final TextEditingController _marinatingCtrl;
  late final TextEditingController _notesCtrl;
  late final TextEditingController _storyCtrl;
  late int _difficulty;
  late FrequencyType _frequency;

  @override
  void initState() {
    super.initState();
    final r = widget.recipe;
    _nameCtrl = TextEditingController(text: r.name);
    _servingsCtrl = TextEditingController(text: '${r.servings}');
    _prepCtrl = TextEditingController(
        text: r.prepTimeMinutes > 0 ? '${r.prepTimeMinutes}' : '');
    _cookCtrl = TextEditingController(
        text: r.cookTimeMinutes > 0 ? '${r.cookTimeMinutes}' : '');
    _marinatingCtrl = TextEditingController(
        text: r.marinatingTimeMinutes > 0 ? '${r.marinatingTimeMinutes}' : '');
    _notesCtrl = TextEditingController(text: r.notes);
    _storyCtrl = TextEditingController(text: r.story);
    _difficulty = r.difficulty;
    _frequency = r.desiredFrequency;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _servingsCtrl.dispose();
    _prepCtrl.dispose();
    _cookCtrl.dispose();
    _marinatingCtrl.dispose();
    _notesCtrl.dispose();
    _storyCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final updated = widget.recipe.copyWith(
      name: _nameCtrl.text.trim(),
      servings: int.tryParse(_servingsCtrl.text.trim()) ?? widget.recipe.servings,
      difficulty: _difficulty,
      prepTimeMinutes: int.tryParse(_prepCtrl.text.trim()) ?? 0,
      cookTimeMinutes: int.tryParse(_cookCtrl.text.trim()) ?? 0,
      marinatingTimeMinutes: int.tryParse(_marinatingCtrl.text.trim()) ?? 0,
      desiredFrequency: _frequency,
      notes: _notesCtrl.text.trim(),
      story: _storyCtrl.text.trim(),
    );
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.92,
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.recipeInfoEditSheetTitle,
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Scrollable form
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8 + bottomInset),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.recipeName,
                        border: const OutlineInputBorder(),
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.recipeNameRequired
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Servings
                    TextFormField(
                      controller: _servingsCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.servings,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final n = int.tryParse(v?.trim() ?? '');
                        if (n == null || n < 1) {
                          return l10n.servingsMustBePositive;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Difficulty
                    Text(l10n.difficultyLevel,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(5, (i) {
                        final level = i + 1;
                        return GestureDetector(
                          onTap: () => setState(() => _difficulty = level),
                          child: Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Icon(
                              level <= _difficulty
                                  ? Icons.battery_full
                                  : Icons.battery_0_bar,
                              size: 28,
                              color: level <= _difficulty
                                  ? Colors.green
                                  : theme.colorScheme.outline,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // Prep / Cook / Marinating times in a row
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _prepCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.prepTimeMin,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _cookCtrl,
                            decoration: InputDecoration(
                              labelText: l10n.cookTimeMin,
                              border: const OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _marinatingCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.marinatingTimeMin,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Desired frequency
                    DropdownButtonFormField<FrequencyType>(
                      initialValue: _frequency,
                      decoration: InputDecoration(
                        labelText: l10n.desiredFrequency,
                        border: const OutlineInputBorder(),
                      ),
                      items: FrequencyType.values.map((f) {
                        return DropdownMenuItem(
                          value: f,
                          child: Text(f.getLocalizedDisplayName(context)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _frequency = v);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Notes
                    TextFormField(
                      controller: _notesCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.notes,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),

                    // Story
                    TextFormField(
                      controller: _storyCtrl,
                      decoration: InputDecoration(
                        labelText: l10n.recipeStoryLabel,
                        hintText: l10n.recipeStoryHint,
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomPadding),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _save,
                    child: Text(l10n.save),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
