import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entry.dart';
import '../widgets/highlighted_text.dart';
// TODO: adjust this import/name to match your create-entry screen
import 'create_entry_screen.dart';

class EntryDetailScreen extends StatefulWidget {
  final Entry entry;
  final String highlight;

  const EntryDetailScreen({
    super.key,
    required this.entry,
    this.highlight = '',
  });

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  late Entry _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  Color _tagColor(String tag) {
    const colors = {
      'Travel': Colors.pink,
      'Food': Colors.orange,
      'Erasmus': Colors.cyan,
      'Ideas': Colors.green,
      'Culture': Colors.red,
      'Other': Colors.yellow,
    };
    return colors[tag] ?? Colors.grey;
  }

  void _openFullImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 5,
              child: Image.file(
                File(_entry.imagePath!),
                errorBuilder: (context, error, stack) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white,
                  size: 64,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _editEntry() async {
    // Your create screen must accept an optional `entry` and
    // return the updated Entry via Navigator.pop(context, updatedEntry).
    final updated = await Navigator.push<Entry>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateEntryScreen(entry: _entry),
      ),
    );

    if (updated != null && mounted) {
      setState(() => _entry = updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateString = DateFormat('d MMMM yyyy').format(_entry.date);

    // When the user goes back, hand the (possibly edited) entry to the feed
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pop(context, _entry);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Memory'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Edit memory',
              onPressed: _editEntry,
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  // Makes the content fill the whole screen, even for short entries
                  constraints:
                  BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_entry.imagePath != null)
                        GestureDetector(
                          onTap: _openFullImage,
                          child: Image.file(
                            File(_entry.imagePath!),
                            width: double.infinity,
                            fit: BoxFit.fitWidth,
                            errorBuilder: (context, error, stack) =>
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: scheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HighlightedText(
                              text: _entry.title,
                              query: widget.highlight,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(Icons.auto_stories,
                                    size: 16, color: scheme.onSurfaceVariant),
                                const SizedBox(width: 6),
                                Text(
                                  dateString,
                                  style:
                                  TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            HighlightedText(
                              text: _entry.text,
                              query: widget.highlight,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                            if (_entry.tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: _entry.tags.map((tag) {
                                  return Chip(
                                    label: Text(tag,
                                        style: const TextStyle(fontSize: 12)),
                                    backgroundColor:
                                    _tagColor(tag).withValues(alpha: 0.2),
                                    side: BorderSide(color: _tagColor(tag)),
                                    visualDensity: VisualDensity.compact,
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}