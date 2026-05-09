import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/preferences_store.dart';
import '../../providers/task_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late int _reminder;
  late int _dndStart;
  late int _dndEnd;

  @override
  void initState() {
    super.initState();
    _reminder = PreferencesStore.defaultReminderMinutes;
    _dndStart = PreferencesStore.dndStartHour;
    _dndEnd = PreferencesStore.dndEndHour;
  }

  Future<void> _persist() async {
    await PreferencesStore.setDefaultReminderMinutes(_reminder);
    await PreferencesStore.setDndHours(startHour: _dndStart, endHour: _dndEnd);
    await ref.read(taskProvider.notifier).refreshAllReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved. Reminders rescheduled.')));
    }
  }

  void _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out successfully.')));
      setState(() {}); // Rebuild to update UI
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Intelligence & alerts')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Defaults',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'New tasks inherit the reminder lead time unless you override per task.',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.bell, size: 20),
              const SizedBox(width: 12),
              Text('Remind ${_reminder == 0 ? 'off' : "$_reminder min before"}'),
              const Spacer(),
              DropdownButton<int>(
                value: _reminder,
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Off')),
                  DropdownMenuItem(value: 5, child: Text('5 min')),
                  DropdownMenuItem(value: 15, child: Text('15 min')),
                  DropdownMenuItem(value: 30, child: Text('30 min')),
                  DropdownMenuItem(value: 60, child: Text('60 min')),
                ],
                onChanged: (v) => setState(() => _reminder = v ?? _reminder),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Text(
            'Quiet hours',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No push reminder is scheduled if it would fire during quiet hours (cross-midnight supported).',
            style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(LucideIcons.moon, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('Start ${_dndStart.toString().padLeft(2, '0')}:00')),
              DropdownButton<int>(
                value: _dndStart,
                items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('$h:00'))],
                onChanged: (v) => setState(() => _dndStart = v ?? _dndStart),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(LucideIcons.sunrise, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text('End ${_dndEnd.toString().padLeft(2, '0')}:00')),
              DropdownButton<int>(
                value: _dndEnd,
                items: [for (var h = 0; h < 24; h++) DropdownMenuItem(value: h, child: Text('$h:00'))],
                onChanged: (v) => setState(() => _dndEnd = v ?? _dndEnd),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Tooltip(
            message: 'Apply and save all settings',
            child: FilledButton.icon(
              onPressed: _persist,
              icon: const Icon(LucideIcons.save),
              label: const Text('Save & reschedule'),
            ),
          ),
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Account',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return Text(
                  'Not signed in. Connect to sync your tasks across devices.',
                  style: TextStyle(color: Theme.of(context).hintColor, fontSize: 13),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Signed in as ${user.email}', style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 12),
                  Tooltip(
                    message: 'Log out of your account',
                    child: OutlinedButton.icon(
                      onPressed: _signOut,
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: const Text('Sign out'),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
