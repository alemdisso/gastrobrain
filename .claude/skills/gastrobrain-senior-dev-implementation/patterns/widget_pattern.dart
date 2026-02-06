// =============================================================================
// Widget Pattern Template
// =============================================================================
// Reference: lib/screens/weekly_plan_screen.dart
//
// This file demonstrates the standard patterns for:
// 1. StatefulWidget with State class
// 2. initState() with ServiceProvider
// 3. dispose() for cleanup
// 4. mounted checks before setState()
// 5. Dependency injection for testing
// =============================================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../core/di/service_provider.dart';
import '../core/services/my_service.dart';
import '../core/services/snackbar_service.dart';
import '../core/providers/my_provider.dart';
import '../l10n/app_localizations.dart';
import '../models/my_model.dart';

// -----------------------------------------------------------------------------
// STATEFUL WIDGET PATTERN
// -----------------------------------------------------------------------------
// Use when: Widget needs to manage local state or lifecycle
// Reference: lib/screens/weekly_plan_screen.dart
// -----------------------------------------------------------------------------

/// Screen for [feature description]
class MyScreen extends StatefulWidget {
  /// Optional database helper for testing
  /// If null, uses ServiceProvider
  final DatabaseHelper? databaseHelper;

  const MyScreen({
    super.key,
    this.databaseHelper,
  });

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // ---------------------------------------------------------------------------
  // STATE VARIABLES
  // ---------------------------------------------------------------------------

  /// Database helper - initialized in initState
  late DatabaseHelper _dbHelper;

  /// Service for business logic
  late MyService _service;

  /// Loading state
  bool _isLoading = true;

  /// Data from database
  List<MyModel> _items = [];

  /// Controllers - must be disposed
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // ---------------------------------------------------------------------------
  // LIFECYCLE METHODS
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    // Initialize with injected helper or ServiceProvider
    _dbHelper = widget.databaseHelper ?? ServiceProvider.database.dbHelper;
    _service = MyService(_dbHelper);

    // Load initial data
    _loadData();
  }

  @override
  void dispose() {
    // Clean up controllers
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // DATA LOADING
  // ---------------------------------------------------------------------------

  /// Loads data from database
  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final items = await _service.getAll();

      // CRITICAL: Check mounted before setState
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.errorLoadingData,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // EVENT HANDLERS
  // ---------------------------------------------------------------------------

  /// Handles item tap
  Future<void> _handleItemTap(MyModel item) async {
    // Show options dialog
    final action = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(AppLocalizations.of(context)!.itemOptions),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'view'),
            child: Text(AppLocalizations.of(context)!.viewDetails),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'edit'),
            child: Text(AppLocalizations.of(context)!.edit),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text(AppLocalizations.of(context)!.delete),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
        ],
      ),
    );

    if (action == null) return;

    switch (action) {
      case 'view':
        await _handleView(item);
        break;
      case 'edit':
        await _handleEdit(item);
        break;
      case 'delete':
        await _handleDelete(item);
        break;
    }
  }

  Future<void> _handleView(MyModel item) async {
    // Navigate to details
    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MyDetailsScreen(
          item: item,
          databaseHelper: _dbHelper,
        ),
      ),
    );
  }

  Future<void> _handleEdit(MyModel item) async {
    // Show edit dialog and reload if changed
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MyEditDialog(
        item: item,
        databaseHelper: _dbHelper,
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }

  Future<void> _handleDelete(MyModel item) async {
    try {
      await _service.delete(item.id);

      if (mounted) {
        SnackbarService.showSuccess(
          context,
          AppLocalizations.of(context)!.itemDeleted,
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        SnackbarService.showError(
          context,
          AppLocalizations.of(context)!.errorDeletingItem,
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // BUILD METHODS
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: AppLocalizations.of(context)!.refresh,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAdd,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return _buildEmptyState();
    }

    return _buildList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noItemsFound,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.addFirstItem,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return _buildListItem(item);
      },
    );
  }

  Widget _buildListItem(MyModel item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.name),
        subtitle: item.description != null ? Text(item.description!) : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _handleItemTap(item),
      ),
    );
  }

  Future<void> _handleAdd() async {
    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => MyAddDialog(
        databaseHelper: _dbHelper,
      ),
    );

    if (result == true && mounted) {
      _loadData();
    }
  }
}

// -----------------------------------------------------------------------------
// WIDGET WITH PROVIDER PATTERN
// -----------------------------------------------------------------------------
// Use when: Widget consumes state from a Provider
// Reference: lib/screens/recipe_list_screen.dart
// -----------------------------------------------------------------------------

/// Screen that uses Provider for state management
class MyProviderScreen extends StatelessWidget {
  const MyProviderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MyProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(AppLocalizations.of(context)!.errorOccurred),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => provider.refresh(),
                  child: Text(AppLocalizations.of(context)!.retry),
                ),
              ],
            ),
          );
        }

        if (provider.items.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context)!.noItemsFound),
          );
        }

        return ListView.builder(
          itemCount: provider.items.length,
          itemBuilder: (context, index) {
            final item = provider.items[index];
            return ListTile(
              title: Text(item.name),
              onTap: () => _handleTap(context, item),
            );
          },
        );
      },
    );
  }

  void _handleTap(BuildContext context, MyModel item) {
    // Handle tap using context.read for actions
    context.read<MyProvider>().selectItem(item);
  }
}
