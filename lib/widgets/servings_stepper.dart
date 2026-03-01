// lib/widgets/servings_stepper.dart

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class ServingsStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  const ServingsStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.people, color: Theme.of(context).hintColor),
        const SizedBox(width: 12),
        Expanded(
          child: Text(AppLocalizations.of(context)!.numberOfServings),
        ),
        IconButton(
          key: const Key('servings_decrement_button'),
          icon: const Icon(Icons.remove),
          onPressed: value > min ? () => onChanged(value - 1) : null,
        ),
        Text(
          '$value',
          key: const Key('servings_value_display'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        IconButton(
          key: const Key('servings_increment_button'),
          icon: const Icon(Icons.add),
          onPressed: () => onChanged(value + 1),
        ),
      ],
    );
  }
}
