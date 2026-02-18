import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';
import '../../l10n/app_localizations.dart';

/// Hero section at the top of the dashboard.
///
/// Displays the app tagline, a brief description of the recommendation
/// engine, and a primary CTA button to navigate to the weekly plan.
class HeroSection extends StatelessWidget {
  final VoidCallback onPlanThisWeek;

  const HeroSection({
    super.key,
    required this.onPlanThisWeek,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DesignTokens.spacingLg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DesignTokens.primary,
            DesignTokens.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(DesignTokens.borderRadiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dashboardTagline,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: DesignTokens.textOnPrimary,
              fontWeight: DesignTokens.weightBold,
            ),
          ),
          const SizedBox(height: DesignTokens.spacingSm),
          Text(
            l10n.dashboardSubtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: DesignTokens.textOnPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: DesignTokens.spacingMd),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onPlanThisWeek,
              icon: const Icon(Icons.calendar_today),
              label: Text(l10n.planThisWeek),
              style: ElevatedButton.styleFrom(
                backgroundColor: DesignTokens.surface,
                foregroundColor: DesignTokens.primary,
                padding: DesignTokens.buttonLargePadding,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
