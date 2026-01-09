import 'package:flutter/material.dart';
import '../models/meal_type.dart';
import '../l10n/app_localizations.dart';

/// Dialog for selecting the type of meal (lunch, dinner, or meal prep)
class MealTypeDialog extends StatefulWidget {
  /// Optional initial meal type selection
  final MealType? initialMealType;

  const MealTypeDialog({
    super.key,
    this.initialMealType,
  });

  @override
  State<MealTypeDialog> createState() => _MealTypeDialogState();
}

class _MealTypeDialogState extends State<MealTypeDialog> {
  MealType? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialMealType;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      title: Text(l10n.mealTypeQuestion),
      content: RadioGroup<MealType>(
        groupValue: _selectedType,
        onChanged: (value) {
          setState(() {
            _selectedType = value;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: MealType.values.map((type) {
            return ListTile(
              leading: Radio<MealType>(
                value: type,
              ),
              title: Text(type.getDisplayName(l10n)),
              onTap: () {
                setState(() {
                  _selectedType = type;
                });
              },
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Skip: return null
            Navigator.of(context).pop(null);
          },
          child: Text(l10n.mealTypeSkip),
        ),
        ElevatedButton(
          onPressed: () {
            // Save: return selected type (may be null if nothing selected)
            Navigator.of(context).pop(_selectedType);
          },
          child: Text(l10n.mealTypeSave),
        ),
      ],
    );
  }
}
