import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/reminder_provider.dart';
import '../theme/app_colors.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Reminders')),
      body: Consumer<ReminderProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final overdue = provider.overdue;
          final upcoming = provider.upcoming;
          final completed = provider.reminders.where((r) => r.isCompleted).toList();

          if (overdue.isEmpty && upcoming.isEmpty && completed.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.alarm_off, size: 48, color: AppColors.muted),
                  const SizedBox(height: 16),
                  const Text('No reminders', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Set reminders from place details to visit later',
                    style: TextStyle(color: AppColors.muted),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (overdue.isNotEmpty) ...[
                _sectionLabel('Overdue', color: AppColors.destructive),
                ...overdue.map((r) => _reminderTile(context, provider, r, isOverdue: true)),
                const SizedBox(height: 16),
              ],
              if (upcoming.isNotEmpty) ...[
                _sectionLabel('Upcoming'),
                ...upcoming.map((r) => _reminderTile(context, provider, r)),
                const SizedBox(height: 16),
              ],
              if (completed.isNotEmpty) ...[
                _sectionLabel('Completed', color: AppColors.muted),
                ...completed.map((r) => _reminderTile(context, provider, r, isDone: true)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text, {Color color = AppColors.foreground}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _reminderTile(
    BuildContext context,
    ReminderProvider provider,
    dynamic reminder, {
    bool isOverdue = false,
    bool isDone = false,
  }) {
    return Dismissible(
      key: Key(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: AppColors.destructive,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => provider.deleteReminder(reminder.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: isOverdue ? Border.all(color: AppColors.destructive.withOpacity(0.3)) : null,
        ),
        child: ListTile(
          leading: IconButton(
            icon: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone ? AppColors.accent : (isOverdue ? AppColors.destructive : AppColors.primary),
            ),
            onPressed: isDone ? null : () => provider.completeReminder(reminder.id),
          ),
          title: Text(
            reminder.placeName,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              decoration: isDone ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMd().add_jm().format(reminder.reminderTime),
                style: TextStyle(
                  fontSize: 12,
                  color: isOverdue ? AppColors.destructive : AppColors.muted,
                ),
              ),
              if (reminder.note.isNotEmpty)
                Text(reminder.note, style: TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () => provider.deleteReminder(reminder.id),
          ),
        ),
      ),
    );
  }
}
