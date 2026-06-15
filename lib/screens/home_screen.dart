import 'package:flutter/material.dart';
import '../core/repositories/tag_repository.dart';
import '../database/database_helper.dart';
import '../l10n/app_localizations.dart';
import 'dashboard_screen.dart';
import 'migration_error_screen.dart';
import 'weekly_plan_screen.dart';
import 'content_screen.dart';
import 'tools_screen.dart';

class HomePage extends StatefulWidget {
  final DatabaseHelper? databaseHelper;
  final TagRepository? tagRepository;

  const HomePage({super.key, this.databaseHelper, this.tagRepository});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  /// Key for the DashboardScreen to allow triggering refresh from outside.
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey();

  /// Key for the WeeklyPlanScreen to allow triggering scrollToToday from outside.
  final GlobalKey<WeeklyPlanScreenState> _weeklyPlanKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final dbHelper = widget.databaseHelper ?? DatabaseHelper();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await dbHelper.hasFatalMigrationError()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MigrationErrorScreen()),
        );
        return;
      }

      if (await dbHelper.hasPendingMigrationFailure()) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.migrationFailureWarning),
          action: SnackBarAction(
            label: l10n.buttonDismiss,
            onPressed: dbHelper.acknowledgeMigrationFailure,
          ),
          duration: const Duration(seconds: 10),
        ));
      }

      final tagRepository = widget.tagRepository ?? TagRepository(dbHelper);
      if (await tagRepository.hasIncompleteBuiltInVocabulary()) {
        if (!mounted) return;
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(l10n.tagVocabularyIncompleteWarning),
          action: SnackBarAction(
            label: l10n.buttonRepair,
            onPressed: () async {
              try {
                await tagRepository.repairBuiltInVocabulary();
              } catch (_) {
                // Best-effort; user can retry by restarting the app.
              }
            },
          ),
          duration: const Duration(seconds: 10),
        ));
      }
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onPlanToday() {
    _navigateToTab(1);
    // Deferred so the tab switch setState has flushed before we scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _weeklyPlanKey.currentState?.scrollToToday();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final List<Widget> screens = [
      DashboardScreen(
        key: _dashboardKey,
        onNavigateToTab: _navigateToTab,
        onPlanToday: _onPlanToday,
      ),
      WeeklyPlanScreen(key: _weeklyPlanKey),
      const ContentScreen(),
    ];

    // Dashboard and Content have their own headers; Meal Plan uses AppBar
    final bool showAppBar = _selectedIndex == 1;

    return Scaffold(
      appBar: showAppBar
          ? AppBar(
              title: Text(l10n.appTitle),
              actions: [
                IconButton(
                  key: const Key('tools_button'),
                  icon: const Icon(Icons.settings),
                  tooltip: l10n.tools,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ToolsScreen(),
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // If re-selecting Dashboard, trigger a refresh
          if (index == 0 && _selectedIndex != 0) {
            _dashboardKey.currentState?.refreshData();
          }
          _navigateToTab(index);
        },
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home, key: Key('dashboard_tab_icon')),
            label: l10n.dashboard,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today,
                key: Key('meal_plan_tab_icon')),
            label: l10n.mealPlan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.menu_book, key: Key('content_tab_icon')),
            label: l10n.content,
          ),
        ],
      ),
    );
  }
}
