import 'package:flutter/material.dart';
import '../models/tag.dart';
import '../models/tag_type.dart';
import '../core/services/tag_duplicate_checker.dart';
import '../l10n/app_localizations.dart';
/// Displays a per-type tag picker for a recipe form.
///
/// The parent owns [selectedTagIds] and tag-creation side-effects.
/// This widget manages only transient UI state (which section is expanded,
/// current search text).
class TagPickerWidget extends StatefulWidget {
  final List<TagType> tagTypes;
  final Map<String, List<Tag>> tagsByType;
  final List<String> selectedTagIds;
  final void Function(List<String>) onChanged;

  /// Called when the user wants to create a new tag (open types only).
  /// Return the created [Tag] on success, or null to cancel.
  final Future<Tag?> Function(String name, String typeId)? onCreateTag;

  const TagPickerWidget({
    super.key,
    required this.tagTypes,
    required this.tagsByType,
    required this.selectedTagIds,
    required this.onChanged,
    this.onCreateTag,
  });

  @override
  State<TagPickerWidget> createState() => _TagPickerWidgetState();
}

class _TagPickerWidgetState extends State<TagPickerWidget> {
  String? _openTypeId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSection(String typeId) {
    setState(() {
      if (_openTypeId == typeId) {
        _openTypeId = null;
        _searchController.clear();
      } else {
        _openTypeId = typeId;
        _searchController.clear();
      }
    });
  }

  void _selectTag(Tag tag) {
    if (widget.selectedTagIds.contains(tag.id)) return;
    widget.onChanged([...widget.selectedTagIds, tag.id]);
    setState(() {
      _openTypeId = null;
      _searchController.clear();
    });
  }

  void _removeTag(String tagId) {
    widget.onChanged(widget.selectedTagIds.where((id) => id != tagId).toList());
  }

  Future<void> _createAndSelect(String name, String typeId) async {
    final tag = await widget.onCreateTag?.call(name, typeId);
    if (tag != null) _selectTag(tag);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.tags, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final type in widget.tagTypes) _buildTypeSection(context, type, l10n),
      ],
    );
  }

  Widget _buildTypeSection(BuildContext context, TagType type, AppLocalizations l10n) {
    final available = widget.tagsByType[type.id] ?? [];
    final selected = available.where((t) => widget.selectedTagIds.contains(t.id)).toList();
    final isOpen = _openTypeId == type.id;
    final query = _searchController.text.toLowerCase();
    final filtered = isOpen
        ? available.where((t) => t.name.toLowerCase().contains(query)).toList()
        : <Tag>[];
    final checker = TagDuplicateChecker(available);
    final dupResult = isOpen ? checker.check(query) : null;
    final showCreate = isOpen && type.isOpen && query.isNotEmpty && !dupResult!.isExact;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(type.getLocalizedName(l10n), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _toggleSection(type.id),
                icon: Icon(isOpen ? Icons.close : Icons.add, size: 16),
                label: Text(isOpen ? '' : l10n.addTag),
              ),
            ],
          ),
          if (selected.isNotEmpty)
            Wrap(
              spacing: 6,
              children: selected.map((t) => Chip(
                label: Text(t.getLocalizedName(l10n)),
                onDeleted: () => _removeTag(t.id),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )).toList(),
            ),
          if (isOpen) ...[
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchOrAddTag,
                isDense: true,
                prefixIcon: const Icon(Icons.search, size: 18),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              children: [
                for (final t in filtered)
                  if (!widget.selectedTagIds.contains(t.id))
                    ActionChip(
                      label: Text(t.getLocalizedName(l10n)),
                      onPressed: () => _selectTag(t),
                    ),
                if (showCreate)
                  ActionChip(
                    avatar: const Icon(Icons.add, size: 16),
                    label: Text('"${_searchController.text}"'),
                    onPressed: () => _createAndSelect(_searchController.text, type.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
