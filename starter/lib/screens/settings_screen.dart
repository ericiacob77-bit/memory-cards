import 'package:flutter/material.dart';
import '../utils/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final service = NotificationService.instance;
    final enabled = await service.isReminderEnabled();
    final time = await service.getReminderTime();
    if (!mounted) return;
    setState(() {
      _reminderEnabled = enabled;
      _reminderTime = TimeOfDay(hour: time.hour, minute: time.minute);
    });
  }

  Future<void> _toggleReminder(bool enabled) async {
    final service = NotificationService.instance;
    if (enabled) {
      final allowed = await service.requestPermission();
      if (!allowed) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please allow notifications for this app.'),
          ),
        );
        return;
      }
      await service.scheduleReminder(_reminderTime.hour, _reminderTime.minute);
    } else {
      await service.cancelReminder();
    }
    if (!mounted) return;
    setState(() => _reminderEnabled = enabled);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );
    if (picked == null) return;
    await NotificationService.instance
        .scheduleReminder(picked.hour, picked.minute);
    if (!mounted) return;
    setState(() => _reminderTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text('Daily reminder'),
            subtitle: Text(
              _reminderEnabled
                  ? 'Reminder set for ${_reminderTime.format(context)}'
                  : 'Off',
            ),
            value: _reminderEnabled,
            onChanged: _toggleReminder,
          ),
          if (_reminderEnabled)
            ListTile(
              title: const Text('Reminder time'),
              trailing: Text(_reminderTime.format(context)),
              onTap: _pickTime,
            ),
        ],
      ),
    );
  }
}