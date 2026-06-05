import 'package:flutter/material.dart';
import '../../core/repositories/tag_repository.dart';
import '../../l10n/app_localizations.dart';
import '../../models/tag.dart';
import '../../models/tag_type.dart';
import '../tag_picker_widget.dart';

/// Bottom sheet for editing a recipe's tags.
///
/// Loads all tag types, available tags, and the recipe's current tags on open.
/// Returns the selected [List<String>] of tag IDs on save, or null on cancel.
class TagsEditSheet extends StatefulWidget {
  final String recipeId;
  final TagRepository tagRepository;

  const TagsEditSheet({
    super.key,
    required this.recipeId,
    required this.tagRepository,
  });

  @override
  State<TagsEditSheet> createState() => _TagsEditSheetState();
}

class _TagsEditSheetState extends State<TagsEditSheet> {
  bool _isLoading = true;
  String? _error;
  List<TagType> _tagTypes = [];
  Map<String, List<Tag>> _tagsByType = {};
  List<String> _selectedTagIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final tagTypes = await widget.tagRepository.getAllTagTypes();
      final tagsByType = <String, List<Tag>>{};
      for (final type in tagTypes) {
        tagsByType[type.id] = await widget.tagRepository.getTagsByType(type.id);
      }
      final currentTags =
          await widget.tagRepository.getTagsForRecipe(widget.recipeId);
      if (mounted) {
        setState(() {
          _tagTypes = tagTypes;
          _tagsByType = tagsByType;
          _selectedTagIds = currentTags.map((t) => t.id).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Tag?> _createTag(String name, String typeId) async {
    try {
      return await widget.tagRepository.getOrCreateTag(name, typeId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tagsEditSheetTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text(_error!))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: TagPickerWidget(
                          tagTypes: _tagTypes,
                          tagsByType: _tagsByType,
                          selectedTagIds: _selectedTagIds,
                          onChanged: (ids) =>
                              setState(() => _selectedTagIds = ids),
                          onCreateTag: _createTag,
                        ),
                      ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.pop(context, _selectedTagIds),
                child: Text(l10n.save),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
