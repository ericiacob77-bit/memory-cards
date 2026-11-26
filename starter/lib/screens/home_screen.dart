import 'package:flutter/material.dart';

import '../models/entry.dart';
import '../utils/storage.dart';
import '../widgets/entry_card.dart';
import 'create_entry_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Entry> _entries = [];
  String _searchQuery = '';

  List<Entry> get _filteredEntries {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _entries;
    return _entries.where((entry) {
      return entry.title.toLowerCase().contains(query) ||
          entry.text.toLowerCase().contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final saved = await loadEntries();
    if (!mounted) return;
    setState(() => _entries = saved);
  }

  Future<void> _openCreateScreen() async {
    final newEntry = await Navigator.push<Entry>(
      context,
      MaterialPageRoute(builder: (context) => const CreateEntryScreen()),
    );

    if (newEntry != null) {
      setState(() => _entries.insert(0, newEntry));
      saveEntries(_entries);
    }
  }

  Widget _buildFeed() {
    final entries = _filteredEntries;

    if (entries.isEmpty) {
      if (_searchQuery.trim().isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('No results for "${_searchQuery.trim()}"'),
            ],
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text('No memories yet. Time to go on an adventure!'),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _openCreateScreen,
              child: const Text('Create your first memory'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Dismissible(
          key: ValueKey(entry.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete entry?'),
                content: const Text('This cannot be undone.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
                false;
          },
          onDismissed: (direction) {
            setState(() => _entries.removeWhere((e) => e.id == entry.id));
            saveEntries(_entries);
          },
          child: EntryCard(entry: entry, highlight: _searchQuery),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memory Cards (${_entries.length})'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(child: _buildFeed()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add memory',
        onPressed: _openCreateScreen,
        child: const Icon(Icons.add),
      ),
    );
  }
}
