import 'package:flutter/material.dart';
import '../../core/di/service_provider.dart';
import '../../core/services/ingredient_matching_service.dart';
import '../../l10n/app_localizations.dart';
import '../../models/ingredient.dart';
import '../../models/ingredient_category.dart';
import '../../models/ingredient_match.dart';
import '../recipe_editor/parsed_ingredient.dart';
import 'parser_review_row.dart';

/// Self-contained ingredient parser entry widget.
///
/// Accepts a multiline ingredient list (bulk paste or one-at-a-time), parses
/// each line using [IngredientParserService], shows a compact review list, and
/// awaits [onIngredientsConfirmed]. Clears on success; preserves state on
/// failure so the user can retry.
///
/// Rows with no match or low confidence expand automatically. The confirm
/// button is disabled while any row has no resolution (no match and not
/// marked as new).
///
/// Requires [matchingService] to be pre-initialized with the ingredient
/// catalogue before mounting. Use [isServicesReady] to gate the Parse button
/// until initialization is complete.
class IngredientParserSection extends StatefulWidget {
  final IngredientMatchingService matchingService;
  final bool isServicesReady;

  /// Called when the user confirms the ingredient list. Must return [true] on
  /// success — the section clears itself. Returns [false] (or throws) to keep
  /// state intact so the user can retry.
  final Future<bool> Function(List<ParsedIngredient> confirmed)
      onIngredientsConfirmed;

  /// Called when the user taps "Create New Ingredient" for an unresolved row.
  /// The screen shows the creation dialog and returns the persisted [Ingredient],
  /// or null if the user cancelled. The section updates its own state with the
  /// result.
  final Future<Ingredient?> Function(ParsedIngredient parsed) onCreateNew;

  const IngredientParserSection({
    super.key,
    required this.matchingService,
    required this.isServicesReady,
    required this.onIngredientsConfirmed,
    required this.onCreateNew,
  });

  @override
  State<IngredientParserSection> createState() =>
      _IngredientParserSectionState();
}

class _IngredientParserSectionState extends State<IngredientParserSection> {
  final TextEditingController _inputController = TextEditingController();
  List<ParsedIngredient> _ingredients = [];

  /// Tracks which rows are expanded. Keyed by list index; defaults to false.
  /// Reset on every re-parse.
  final Map<int, bool> _expandedState = {};

  /// Incremented on every parse to force TextFormField recreation inside rows.
  int _parseGeneration = 0;

  bool _isSaving = false;

  final _parsedSectionKey = GlobalKey();
  final _manualSectionKey = GlobalKey();

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  // ── Scroll helpers ────────────────────────────────────────────────────────

  void _scrollToKey(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = key.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ── Parsing ──────────────────────────────────────────────────────────────

  void _parseIngredients() {
    final rawText = _inputController.text.trim();
    if (rawText.isEmpty) {
      setState(() {
        _ingredients = [];
        _expandedState.clear();
        _parseGeneration++;
      });
      return;
    }

    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final parsed = <ParsedIngredient>[];
    for (final line in lines) {
      final p = _parseLine(line);
      if (p != null) parsed.add(p);
    }

    setState(() {
      _ingredients = parsed;
      _expandedState.clear();
      // Auto-expand rows that need attention
      for (var i = 0; i < _ingredients.length; i++) {
        if (_needsAttention(_ingredients[i])) {
          _expandedState[i] = true;
        }
      }
      _parseGeneration++;
    });
    if (parsed.isNotEmpty) _scrollToKey(_parsedSectionKey);
  }

  ParsedIngredient? _parseLine(String line) {
    if (!widget.isServicesReady) {
      // Service not ready: treat the whole line as the ingredient name
      return ParsedIngredient(
        quantity: 1.0,
        unit: null,
        name: line,
        category: IngredientCategory.other,
        matches: [],
      );
    }

    final result = ServiceProvider.ingredientParser.parseIngredientLine(line);

    // Auto-select match when confidence >= 0.80
    final selectedMatch =
        result.matches.isNotEmpty && result.matches.first.confidence >= 0.80
            ? result.matches.first
            : null;

    return ParsedIngredient(
      quantity: result.quantity,
      quantityMax: result.quantityMax,
      unit: result.unit,
      name: result.ingredientName,
      category: selectedMatch?.ingredient.category ?? IngredientCategory.other,
      matches: result.matches,
      selectedMatch: selectedMatch,
      notes: result.notes,
    );
  }

  void _addManualRow() {
    setState(() {
      final index = _ingredients.length;
      _ingredients.add(ParsedIngredient(
        quantity: 1.0,
        unit: null,
        name: '',
        category: IngredientCategory.other,
        matches: [],
        isManual: true,
      ));
      _expandedState[index] = true; // manual rows start expanded
      _parseGeneration++;
    });
    _scrollToKey(_manualSectionKey);
  }

  // ── Row mutations ─────────────────────────────────────────────────────────

  void _removeAt(int index) {
    setState(() {
      _ingredients.removeAt(index);
      // Rebuild expand state with shifted indices
      final updated = <int, bool>{};
      _expandedState.forEach((k, v) {
        if (k < index) updated[k] = v;
        if (k > index) updated[k - 1] = v;
      });
      _expandedState
        ..clear()
        ..addAll(updated);
    });
  }

  void _updateQuantity(int index, double qty, double? qtyMax, String? error) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      final ing = _ingredients[index];
      _ingredients[index] = ParsedIngredient(
        quantity: qty,
        quantityMax: qtyMax,
        qtyError: error,
        unit: ing.unit,
        name: ing.name,
        originalName: ing.originalName,
        category: ing.category,
        notes: ing.notes,
        matches: ing.matches,
        selectedMatch: ing.selectedMatch,
        newIngredientToCreate: ing.newIngredientToCreate,
        isManual: ing.isManual,
      );
    });
  }

  void _updateUnit(int index, String? unit) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      final ing = _ingredients[index];
      _ingredients[index] = ParsedIngredient(
        quantity: ing.quantity,
        quantityMax: ing.quantityMax,
        unit: unit,
        name: ing.name,
        originalName: ing.originalName,
        category: ing.category,
        notes: ing.notes,
        matches: ing.matches,
        selectedMatch: ing.selectedMatch,
        newIngredientToCreate: ing.newIngredientToCreate,
        isManual: ing.isManual,
      );
    });
  }

  void _updateName(int index, String name) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      final ing = _ingredients[index];

      // Re-run matching when name changes
      final matches = widget.matchingService.findMatches(name);
      final selectedMatch =
          matches.isNotEmpty &&
                  (widget.matchingService.shouldAutoSelect(matches) ||
                      matches.length == 1)
              ? matches.first
              : null;

      _ingredients[index] = ParsedIngredient(
        quantity: ing.quantity,
        quantityMax: ing.quantityMax,
        unit: ing.unit,
        name: selectedMatch?.ingredient.name ?? name,
        originalName: name,
        category: selectedMatch?.ingredient.category ?? ing.category,
        notes: ing.notes,
        matches: matches,
        selectedMatch: selectedMatch,
        isManual: ing.isManual,
      );
    });
  }

  void _updateNotes(int index, String? notes) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      final ing = _ingredients[index];
      _ingredients[index] = ParsedIngredient(
        quantity: ing.quantity,
        quantityMax: ing.quantityMax,
        unit: ing.unit,
        name: ing.name,
        originalName: ing.originalName,
        category: ing.category,
        notes: notes,
        matches: ing.matches,
        selectedMatch: ing.selectedMatch,
        newIngredientToCreate: ing.newIngredientToCreate,
        isManual: ing.isManual,
      );
    });
  }

  void _updateMatch(int index, IngredientMatch? match) {
    if (index < 0 || index >= _ingredients.length) return;
    setState(() {
      final ing = _ingredients[index];
      _ingredients[index] = ParsedIngredient(
        quantity: ing.quantity,
        quantityMax: ing.quantityMax,
        unit: ing.unit,
        name: match?.ingredient.name ?? ing.name,
        originalName: ing.originalName,
        category: match?.ingredient.category ?? ing.category,
        notes: ing.notes,
        matches: ing.matches,
        selectedMatch: match,
        isManual: ing.isManual,
      );
    });
  }

  Future<void> _markAsNew(int index) async {
    if (index < 0 || index >= _ingredients.length) return;
    final ing = _ingredients[index];
    final result = await widget.onCreateNew(ing);
    if (result != null && mounted) {
      setState(() {
        _ingredients[index] = ParsedIngredient(
          quantity: ing.quantity,
          quantityMax: ing.quantityMax,
          unit: ing.unit,
          name: result.name,
          originalName: ing.originalName,
          category: result.category,
          notes: result.notes,
          matches: ing.matches,
          selectedMatch: null,
          newIngredientToCreate: result,
          isManual: ing.isManual,
        );
      });
    }
  }

  Future<void> _handleCreateNew(int index) async {
    if (index < 0 || index >= _ingredients.length) return;
    final ing = _ingredients[index];
    final result = await widget.onCreateNew(ing);
    if (result != null && mounted) {
      setState(() {
        _ingredients[index] = ParsedIngredient(
          quantity: ing.quantity,
          quantityMax: ing.quantityMax,
          unit: ing.unit,
          name: result.name,
          originalName: ing.originalName,
          category: result.category,
          notes: result.notes,
          matches: ing.matches,
          selectedMatch: null,
          newIngredientToCreate: result,
          isManual: ing.isManual,
        );
      });
    }
  }

  Future<void> _handleConfirm() async {
    if (!_canConfirm || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      final success =
          await widget.onIngredientsConfirmed(List.unmodifiable(_ingredients));
      if (success && mounted) {
        setState(() {
          _ingredients = [];
          _expandedState.clear();
          _inputController.clear();
          _parseGeneration++;
          _isSaving = false;
        });
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _needsAttention(ParsedIngredient ing) {
    if (ing.isManual && ing.name.trim().isEmpty) return true;
    return !ing.isNewIngredient &&
        ing.selectedMatch == null &&
        ing.matches.isEmpty &&
        ing.name.trim().isNotEmpty;
  }

  int get _unresolvedCount => _ingredients.where(_needsAttention).length;

  bool get _canConfirm =>
      _ingredients.isNotEmpty && _unresolvedCount == 0;

  bool get _lastManualRowIsBlank {
    final manualItems = _ingredients.where((i) => i.isManual).toList();
    if (manualItems.isEmpty) return false;
    return manualItems.last.name.trim().isEmpty;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Input area ──────────────────────────────────────────────────────
        TextField(
          controller: _inputController,
          maxLines: 6,
          decoration: InputDecoration(
            labelText: l10n.ingredientParserInputLabel,
            hintText: l10n.ingredientParserHintText,
            border: const OutlineInputBorder(),
            helperText: l10n.ingredientParserHelperText,
            helperMaxLines: 2,
          ),
        ),
        const SizedBox(height: 12),

        // ── Action buttons ──────────────────────────────────────────────────
        Row(
          children: [
            Flexible(
              child: ElevatedButton.icon(
                key: const Key('ingredient_parser_parse_button'),
                onPressed: widget.isServicesReady ? _parseIngredients : null,
                icon: const Icon(Icons.auto_fix_high, size: 18),
                label: Text(l10n.ingredientParserParseButton),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: TextButton.icon(
                onPressed: _lastManualRowIsBlank ? null : _addManualRow,
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.ingredientParserAddManuallyButton),
              ),
            ),
          ],
        ),

        // ── Parsed subsection ───────────────────────────────────────────────
        if (_ingredients.any((i) => !i.isManual)) ...[
          const SizedBox(height: 20),
          Row(
            key: _parsedSectionKey,
            children: [
              Text(
                l10n.ingredientParserReviewTitle(
                    _ingredients.where((i) => !i.isManual).length),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._ingredients.asMap().entries
              .where((e) => !e.value.isManual)
              .map((entry) {
            final index = entry.key;
            final ing = entry.value;
            return ParserReviewRow(
              key: ValueKey('row_${index}_$_parseGeneration'),
              index: index,
              ingredient: ing,
              parseGeneration: _parseGeneration,
              initiallyExpanded: _expandedState[index] ?? false,
              onQuantityChanged: (qty, qtyMax, err) =>
                  _updateQuantity(index, qty, qtyMax, err),
              onUnitChanged: (unit) => _updateUnit(index, unit),
              onNameChanged: (name) => _updateName(index, name),
              onNotesChanged: (notes) => _updateNotes(index, notes),
              onMatchChanged: (match) => _updateMatch(index, match),
              onMarkAsNew: () => _markAsNew(index),
              onRemove: () => _removeAt(index),
              onCreateNew: () => _handleCreateNew(index),
            );
          }),
        ],

        // ── Manual subsection ───────────────────────────────────────────────
        if (_ingredients.any((i) => i.isManual)) ...[
          const SizedBox(height: 20),
          Row(
            key: _manualSectionKey,
            children: [
              Text(
                l10n.ingredientParserManualSectionTitle(
                    _ingredients.where((i) => i.isManual).length),
                style: theme.textTheme.titleSmall,
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._ingredients.asMap().entries
              .where((e) => e.value.isManual)
              .map((entry) {
            final index = entry.key;
            final ing = entry.value;
            return ParserReviewRow(
              key: ValueKey('row_${index}_$_parseGeneration'),
              index: index,
              ingredient: ing,
              parseGeneration: _parseGeneration,
              initiallyExpanded: _expandedState[index] ?? false,
              onQuantityChanged: (qty, qtyMax, err) =>
                  _updateQuantity(index, qty, qtyMax, err),
              onUnitChanged: (unit) => _updateUnit(index, unit),
              onNameChanged: (name) => _updateName(index, name),
              onNotesChanged: (notes) => _updateNotes(index, notes),
              onMatchChanged: (match) => _updateMatch(index, match),
              onMarkAsNew: () => _markAsNew(index),
              onRemove: () => _removeAt(index),
              onCreateNew: () => _handleCreateNew(index),
            );
          }),
        ],

        // ── Confirm bar ─────────────────────────────────────────────────────
        if (_ingredients.isNotEmpty) ...[
          if (_unresolvedCount > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded,
                    size: 14, color: theme.colorScheme.error),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    l10n.ingredientParserUnresolvedWarning(_unresolvedCount),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('ingredient_parser_confirm_button'),
              onPressed: (_canConfirm && !_isSaving) ? _handleConfirm : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                disabledBackgroundColor: _unresolvedCount > 0
                    ? Colors.amber.shade700
                    : theme.colorScheme.onSurface.withValues(alpha: 0.12),
                disabledForegroundColor:
                    _unresolvedCount > 0 ? Colors.white : null,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : Text(
                      l10n.ingredientParserAddAllButton(_ingredients.length),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
