import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Quick actions row on the dashboard.
///
/// Displays 3 action buttons for common workflows:
/// This Week, Add Recipe, Browse Recipes.
class QuickActionsPanel extends StatelessWidget {
  final VoidCallback onViewThisWeek;
  final VoidCallback onAddRecipe;
  final VoidCallback onBrowseRecipes;

  const QuickActionsPanel({
    super.key,
    required this.onViewThisWeek,
    required this.onAddRecipe,
    required this.onBrowseRecipes,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: DesignTokens.spacingSm),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.date_range,
                label: l10n.viewThisWeek,
                color: DesignTokens.accent,
                onTap: onViewThisWeek,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: _ActionCard(
                icon: Icons.add_circle_outline,
                label: l10n.addRecipe,
                color: DesignTokens.info,
                onTap: onAddRecipe,
              ),
            ),
            const SizedBox(width: DesignTokens.spacingSm),
            Expanded(
              child: _ActionCard(
                icon: Icons.menu_book,
                label: l10n.browseRecipes,
                color: DesignTokens.textSecondary,
                onTap: onBrowseRecipes,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: DesignTokens.spacingMd,
            horizontal: DesignTokens.spacingXs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: DesignTokens.iconSizeLarge),
              const SizedBox(height: DesignTokens.spacingSm),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
