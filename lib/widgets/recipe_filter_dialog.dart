import 'package:flutter/material.dart';
import '../models/frequency_type.dart';
import '../models/tag.dart';
import '../models/tag_type.dart';
import '../core/theme/design_tokens.dart';
import '../l10n/app_localizations.dart';

class RecipeFilterResult {
  final Map<String, dynamic> filters;
  final List<Map<String, String>> tagFilters;

  const RecipeFilterResult({required this.filters, required this.tagFilters});
}

class RecipeFilterDialog extends StatefulWidget {
  final Map<String, dynamic> initialFilters;
  final List<Map<String, String>> initialTagFilters;
  final List<TagType> tagTypes;
  final Map<String, List<Tag>> tagsByType;

  const RecipeFilterDialog({
    super.key,
    required this.initialFilters,
    required this.initialTagFilters,
    required this.tagTypes,
    required this.tagsByType,
  });

  @override
  State<RecipeFilterDialog> createState() => _RecipeFilterDialogState();
}

class _RecipeFilterDialogState extends State<RecipeFilterDialog> {
  late int? _difficulty;
  late int? _rating;
  late String? _frequency;
  late Set<String> _selectedTagKeys; // 'typeId::tagName'

  @override
  void initState() {
    super.initState();
    _difficulty = widget.initialFilters['difficulty'] as int?;
    _rating = widget.initialFilters['rating'] as int?;
    _frequency = widget.initialFilters['desired_frequency'] as String?;
    _selectedTagKeys = {
      for (final tf in widget.initialTagFilters)
        '${tf['type_id']}::${tf['name']}',
    };
  }

  void _clear() => setState(() {
        _difficulty = null;
        _rating = null;
        _frequency = null;
        _selectedTagKeys.clear();
      });

  void _apply() {
    final filters = <String, dynamic>{
      if (_difficulty != null) 'difficulty': _difficulty,
      if (_rating != null) 'rating': _rating,
      if (_frequency != null) 'desired_frequency': _frequency,
    };
    final typeIsHard = {for (final t in widget.tagTypes) t.id: t.isHard};
    final tagFilters = _selectedTagKeys.map((key) {
      final parts = key.split('::');
      final typeId = parts[0];
      return {
        'type_id': typeId,
        'name': parts[1],
        'is_hard': typeIsHard[typeId] == true ? 'true' : 'false',
      };
    }).toList();
    Navigator.pop(context, RecipeFilterResult(filters: filters, tagFilters: tagFilters));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.filterRecipes),
      content: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.65,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDifficulty(l10n),
              const SizedBox(height: 16),
              _buildRating(l10n),
              const SizedBox(height: 16),
              _buildFrequency(l10n),
              if (widget.tagTypes.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 4),
                Text(l10n.filterByTags, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                for (final type in widget.tagTypes)
                  _buildTagSection(type),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _clear, child: Text(l10n.clear)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
        TextButton(onPressed: _apply, child: Text(l10n.apply)),
      ],
    );
  }

  Widget _buildDifficulty(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.maxDifficulty),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => IconButton(
            icon: Icon(
              i < (_difficulty ?? -1) ? Icons.battery_full : Icons.battery_0_bar,
              color: i < (_difficulty ?? -1) ? DesignTokens.success : DesignTokens.textSecondary,
            ),
            onPressed: () => setState(
              () => _difficulty = (_difficulty == i + 1) ? null : i + 1,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildRating(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.minimumRating),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) => IconButton(
            icon: Icon(
              i < (_rating ?? -1) ? Icons.star : Icons.star_border,
              color: i < (_rating ?? -1) ? Colors.amber : DesignTokens.textSecondary,
            ),
            onPressed: () => setState(
              () => _rating = (_rating == i + 1) ? null : i + 1,
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildFrequency(AppLocalizations l10n) {
    return DropdownButtonFormField<String>(
      initialValue: _frequency,
      decoration: InputDecoration(labelText: l10n.minimumFrequency),
      items: [
        DropdownMenuItem(value: null, child: Text(l10n.any)),
        ...FrequencyType.values.map((f) => DropdownMenuItem(
              value: f.value,
              child: Text(f.getLocalizedDisplayName(context)),
            )),
      ],
      onChanged: (v) => setState(() => _frequency = v),
    );
  }

  Widget _buildTagSection(TagType type) {
    final tags = widget.tagsByType[type.id] ?? [];
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(type.getLocalizedName(AppLocalizations.of(context)!), style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            children: tags.map((tag) {
              final key = '${type.id}::${tag.name}';
              final selected = _selectedTagKeys.contains(key);
              return FilterChip(
                label: Text(tag.getLocalizedName(AppLocalizations.of(context)!)),
                selected: selected,
                onSelected: (v) => setState(() {
                  v ? _selectedTagKeys.add(key) : _selectedTagKeys.remove(key);
                }),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
