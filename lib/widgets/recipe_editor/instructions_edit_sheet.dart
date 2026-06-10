import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../l10n/app_localizations.dart';

/// Full-height bottom sheet for editing recipe instructions with
/// edit/preview toggle.
///
/// Returns the new instructions string on save, or null on cancel.
class InstructionsEditSheet extends StatefulWidget {
  final String initialInstructions;

  const InstructionsEditSheet({
    super.key,
    required this.initialInstructions,
  });

  @override
  State<InstructionsEditSheet> createState() => _InstructionsEditSheetState();
}

class _InstructionsEditSheetState extends State<InstructionsEditSheet> {
  late final TextEditingController _controller;
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialInstructions);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.editInstructions,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                SegmentedButton<bool>(
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text(l10n.instructionsEditLabel),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text(l10n.instructionsPreviewLabel),
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                    ),
                  ],
                  selected: {_isPreview},
                  onSelectionChanged: (v) =>
                      setState(() => _isPreview = v.first),
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),

          // Content area
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 8 + bottomInset,
              ),
              child: _isPreview
                  ? SingleChildScrollView(
                      child: MarkdownBody(
                        data: _controller.text.isEmpty
                            ? '_${l10n.enterInstructions}_'
                            : _controller.text,
                        shrinkWrap: true,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(theme).copyWith(
                          p: const TextStyle(fontSize: 16, height: 1.5),
                        ),
                      ),
                    )
                  : TextField(
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: InputDecoration(
                        hintText: l10n.enterInstructions,
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                      keyboardType: TextInputType.multiline,
                      onChanged: (_) => setState(() {}),
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
                    child: Text(l10n.buttonCancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, _controller.text),
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
