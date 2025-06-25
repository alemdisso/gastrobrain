import 'package:flutter/material.dart';
import 'package:gastrobrain/l10n/app_localizations.dart';

/// Test utility for wrapping widgets with localization context.
/// 
/// This ensures that widgets using AppLocalizations.of(context) 
/// work properly in tests by providing the necessary localization delegates.
Widget wrapWithLocalizations(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt', 'BR'),
    home: child,
  );
}

/// Alternative wrapper that preserves existing MaterialApp properties
/// while adding localization support.
Widget wrapWithLocalizationsAndMaterial(Widget child, {
  ThemeData? theme,
  String? title,
}) {
  return MaterialApp(
    title: title ?? 'Test App',
    theme: theme ?? ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
    ),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('pt', 'BR'),
    home: child,
  );
}