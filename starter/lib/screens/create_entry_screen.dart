import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../data/sample_entries.dart'; // for availableTags
import '../models/entry.dart';

class CreateEntryScreen extends StatefulWidget {
  final Entry? entry; // null = creating, not null = editing

  const CreateEntryScreen({super.key, this.entry});

  @override
  State<CreateEntryScreen> createState() => _CreateEntryScreenState();
}

class _CreateEntryScreenState extends State<CreateEntryScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;

  late DateTime _selectedDate;

  // Selected tags (a Set prevents duplicates)
  late final Set<String> _selectedTags;

  // Path of the picked photo (null = no photo)
  String? _imagePath;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleController = TextEditingController(text: e?.title ?? '');
    _textController = TextEditingController(text: e?.text ?? '');
    _selectedDate = e?.date ?? DateTime.now();
    _selectedTags = {...?e?.tags};
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compress slightly to save storage
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  void _save() {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a title'),
          backgroundColor: Colors.red.shade400,
        ),
      );
      return;
    }

    final result = Entry(
      // Keep the old id when editing so the feed can replace the right entry
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      text: _textController.text.trim(),
      date: _selectedDate,
      tags: _selectedTags.toList(), // Set -> List
      imagePath: _imagePath,
    );

    Navigator.pop(context, result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Memory' : 'New Memory'),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(_isEditing ? 'Update' : 'Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Give this memory a name',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'What happened?',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today),
                label:
                Text(DateFormat('EEE, d MMM yyyy').format(_selectedDate)),
              ),

              // Tag chips
              const SizedBox(height: 16),
              const Text(
                'Tags',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: availableTags.map((tag) {
                  return FilterChip(
                    label: Text(tag),
                    selected: _selectedTags.contains(tag),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              // Photo preview or "Add Photo" button
              const SizedBox(height: 16),
              if (_imagePath != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(_imagePath!),
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 200,
                      width: double.infinity,
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _pickPhoto,
                      icon: const Icon(Icons.swap_horiz),
                      label: const Text('Change photo'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _imagePath = null),
                      child: const Text('Remove photo'),
                    ),
                  ],
                ),
              ] else
                OutlinedButton.icon(
                  onPressed: _pickPhoto,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Add Photo'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}