import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/reminder_provider.dart';
import 'models/plant_care_reminder.dart';

class PlantCareRemindersScreen extends StatefulWidget {
  final String? initialPlantName;
  final String? initialPlantId;
  final String? initialImageUrl;
  final int? initialFrequencyDays;

  const PlantCareRemindersScreen({
    super.key,
    this.initialPlantName,
    this.initialPlantId,
    this.initialImageUrl,
    this.initialFrequencyDays,
  });

  @override
  State<PlantCareRemindersScreen> createState() => _PlantCareRemindersScreenState();
}

class _PlantCareRemindersScreenState extends State<PlantCareRemindersScreen> {
  CareType? _selectedFilter;
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    if (widget.initialPlantName != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showAddEditReminderSheet(
          prefilledPlantName: widget.initialPlantName,
          prefilledPlantId: widget.initialPlantId,
          prefilledImageUrl: widget.initialImageUrl,
          prefilledFrequency: widget.initialFrequencyDays,
        );
      });
    }
  }

  void _showAddEditReminderSheet({
    PlantCareReminder? existing,
    String? prefilledPlantName,
    String? prefilledPlantId,
    String? prefilledImageUrl,
    int? prefilledFrequency,
  }) {
    final isEditing = existing != null;
    final nameCtrl = TextEditingController(
      text: existing?.plantName ?? prefilledPlantName ?? '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    CareType careType = existing?.careType ?? CareType.watering;
    int frequencyDays = existing?.frequencyDays ?? prefilledFrequency ?? 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(sheetCtx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? 'Edit Care Reminder' : 'Add Plant Care Reminder',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textMuted),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Plant Name Field
                    const Text(
                      'Plant Name',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Monstera Deliciosa, Snake Plant',
                        prefixIcon: const Icon(Icons.local_florist_outlined, color: AppColors.botanicalGreen),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Care Type Selector
                    const Text(
                      'Care Task',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: CareType.values.map((type) {
                        final isSel = careType == type;
                        return ChoiceChip(
                          avatar: Text(type.emoji),
                          label: Text(type.label),
                          selected: isSel,
                          selectedColor: AppColors.botanicalGreenLight,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => careType = type);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Frequency Selector
                    const Text(
                      'Frequency',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        {'label': 'Daily', 'days': 1},
                        {'label': 'Every 2 days', 'days': 2},
                        {'label': 'Every 3 days', 'days': 3},
                        {'label': 'Weekly', 'days': 7},
                        {'label': 'Bi-weekly', 'days': 14},
                        {'label': 'Monthly', 'days': 30},
                      ].map((item) {
                        final days = item['days'] as int;
                        final label = item['label'] as String;
                        final isSel = frequencyDays == days;
                        return ChoiceChip(
                          label: Text(label),
                          selected: isSel,
                          selectedColor: AppColors.botanicalGreenLight,
                          labelStyle: TextStyle(
                            color: isSel ? AppColors.botanicalGreenDark : AppColors.textPrimary,
                            fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => frequencyDays = days);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Notes Field
                    const Text(
                      'Special Care Notes (Optional)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'e.g. Mist leaves twice weekly, check moisture first...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(sheetCtx).showSnackBar(
                              const SnackBar(
                                content: Text('Please enter a plant name.'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            return;
                          }

                          final provider = context.read<ReminderProvider>();
                          if (isEditing) {
                            provider.updateReminder(
                              existing.copyWith(
                                plantName: name,
                                careType: careType,
                                frequencyDays: frequencyDays,
                                notes: notesCtrl.text.trim(),
                              ),
                            );
                          } else {
                            final newReminder = PlantCareReminder(
                              id: DateTime.now().millisecondsSinceEpoch.toString(),
                              plantName: name,
                              plantId: prefilledPlantId,
                              imageUrl: prefilledImageUrl,
                              careType: careType,
                              frequencyDays: frequencyDays,
                              nextDueDate: DateTime.now(), // starts due immediately for user verification
                              notes: notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                            );
                            provider.addReminder(newReminder);
                          }

                          Navigator.pop(sheetCtx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isEditing
                                    ? 'Reminder updated!'
                                    : 'Care reminder added for $name!',
                              ),
                              backgroundColor: AppColors.botanicalGreen,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.botanicalGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'Save Changes' : 'Create Reminder',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnoozeDialog(PlantCareReminder reminder) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snooze ${reminder.careType.label} for ${reminder.plantName}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Select how long to postpone this task:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.botanicalGreen),
              title: const Text('1 Day (Tomorrow)'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().snooze(reminder.id, 1);
                _showStatusSnackBar('Snoozed for 1 day.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.botanicalGreen),
              title: const Text('2 Days'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().snooze(reminder.id, 2);
                _showStatusSnackBar('Snoozed for 2 days.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.botanicalGreen),
              title: const Text('3 Days'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().snooze(reminder.id, 3);
                _showStatusSnackBar('Snoozed for 3 days.');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today, color: AppColors.botanicalGreen),
              title: const Text('1 Week'),
              onTap: () {
                Navigator.pop(ctx);
                context.read<ReminderProvider>().snooze(reminder.id, 7);
                _showStatusSnackBar('Snoozed for 1 week.');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.botanicalGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reminderProv = context.watch<ReminderProvider>();
    final allReminders = reminderProv.reminders;

    final filtered = _selectedFilter == null
        ? allReminders
        : allReminders.where((r) => r.careType == _selectedFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Plant Care Reminders'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_alert_rounded, color: AppColors.botanicalGreen),
            tooltip: 'Add Care Reminder',
            onPressed: () => _showAddEditReminderSheet(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Stats Header Banner ───────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildStatCard(
                      label: 'Due Today',
                      count: reminderProv.dueTodayCount,
                      color: AppColors.botanicalGreen,
                      icon: Icons.notifications_active_outlined,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Overdue',
                      count: reminderProv.overdueCount,
                      color: AppColors.error,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      label: 'Total Active',
                      count: allReminders.length,
                      color: AppColors.primaryBlue,
                      icon: Icons.yard_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Filter Chips ──────────────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All Tasks'),
                        selected: _selectedFilter == null,
                        selectedColor: AppColors.botanicalGreenLight,
                        labelStyle: TextStyle(
                          color: _selectedFilter == null
                              ? AppColors.botanicalGreenDark
                              : AppColors.textPrimary,
                          fontWeight: _selectedFilter == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = null),
                      ),
                      const SizedBox(width: 8),
                      ...CareType.values.map((type) {
                        final isSel = _selectedFilter == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            avatar: Text(type.emoji),
                            label: Text(type.label),
                            selected: isSel,
                            selectedColor: AppColors.botanicalGreenLight,
                            labelStyle: TextStyle(
                              color: isSel
                                  ? AppColors.botanicalGreenDark
                                  : AppColors.textPrimary,
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) {
                              setState(() {
                                _selectedFilter = isSel ? null : type;
                              });
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Reminder List ─────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.botanicalGreenLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.spa_outlined,
                              size: 48,
                              color: AppColors.botanicalGreen,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Care Tasks Scheduled',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Keep your indoor & garden plants thriving by setting watering, fertilizing, and repotting reminders.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () => _showAddEditReminderSheet(),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Your First Reminder'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.botanicalGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = filtered[i];
                      return _ReminderCard(
                        reminder: item,
                        dateFormat: _dateFormat,
                        onMarkDone: () {
                          context.read<ReminderProvider>().markDone(item.id);
                          _showStatusSnackBar(
                            'Done! Scheduled next ${item.careType.label.toLowerCase()} in ${item.frequencyDays} days.',
                          );
                        },
                        onSnooze: () => _showSnoozeDialog(item),
                        onEdit: () => _showAddEditReminderSheet(existing: item),
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: const Text('Delete Reminder?'),
                              content: Text('Remove ${item.careType.label} reminder for ${item.plantName}?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dCtx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(dCtx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            context.read<ReminderProvider>().deleteReminder(item.id);
                            _showStatusSnackBar('Reminder deleted.');
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditReminderSheet(),
        backgroundColor: AppColors.botanicalGreen,
        icon: const Icon(Icons.alarm_add_rounded, color: Colors.white),
        label: const Text(
          'Add Reminder',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final PlantCareReminder reminder;
  final DateFormat dateFormat;
  final VoidCallback onMarkDone;
  final VoidCallback onSnooze;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReminderCard({
    required this.reminder,
    required this.dateFormat,
    required this.onMarkDone,
    required this.onSnooze,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBgColor;

    if (reminder.isOverdue) {
      statusColor = AppColors.error;
      statusBgColor = const Color(0xFFFEE2E2);
    } else if (reminder.isDueToday) {
      statusColor = AppColors.botanicalGreenDark;
      statusBgColor = AppColors.botanicalGreenLight;
    } else {
      statusColor = AppColors.primaryBlue;
      statusBgColor = const Color(0xFFEFF6FF);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: reminder.isDueToday || reminder.isOverdue
              ? statusColor.withValues(alpha: 0.3)
              : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Care Icon Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.botanicalGreenLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  reminder.careType.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 12),

              // Title & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.plantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          reminder.careType.label,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.botanicalGreen,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('•', style: TextStyle(color: AppColors.textMuted)),
                        const SizedBox(width: 6),
                        Text(
                          'Every ${reminder.frequencyDays} ${reminder.frequencyDays == 1 ? 'day' : 'days'}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Due status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  reminder.dueStatusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),

              // Popup menu
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
                onSelected: (val) {
                  if (val == 'edit') onEdit();
                  if (val == 'delete') onDelete();
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 18),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: AppColors.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (reminder.notes != null && reminder.notes!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                reminder.notes!,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],

          if (reminder.lastCompletedDate != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last completed: ${dateFormat.format(reminder.lastCompletedDate!)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Action Buttons: Mark Done & Snooze
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: onMarkDone,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Mark Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.botanicalGreen,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: OutlinedButton.icon(
                  onPressed: onSnooze,
                  icon: const Icon(Icons.snooze, size: 16, color: AppColors.textSecondary),
                  label: const Text('Snooze', style: TextStyle(color: AppColors.textSecondary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
