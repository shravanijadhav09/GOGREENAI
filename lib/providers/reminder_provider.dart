import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/storage/secure_storage_service.dart';
import '../features/reminders/models/plant_care_reminder.dart';

class ReminderProvider extends ChangeNotifier {
  final SecureStorageService _storage = SecureStorageService();

  List<PlantCareReminder> _reminders = [];
  bool _isLoading = false;

  List<PlantCareReminder> get reminders => List.unmodifiable(_reminders);
  bool get isLoading => _isLoading;

  int get dueCount => _reminders.where((r) => r.isDueToday || r.isOverdue).length;
  int get overdueCount => _reminders.where((r) => r.isOverdue).length;
  int get dueTodayCount => _reminders.where((r) => r.isDueToday).length;

  Future<void> loadReminders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final raw = await _storage.getRemindersRaw();
      if (raw != null && raw.isNotEmpty) {
        final list = jsonDecode(raw) as List<dynamic>;
        _reminders = list
            .map((item) => PlantCareReminder.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        // Provide starter reminders so new users immediately see functional care tracking
        _reminders = [
          PlantCareReminder(
            id: 'starter-1',
            plantName: 'Snake Plant',
            careType: CareType.watering,
            frequencyDays: 7,
            nextDueDate: DateTime.now(), // Due today
            notes: 'Allow soil to dry out completely between waterings.',
          ),
          PlantCareReminder(
            id: 'starter-2',
            plantName: 'Peace Lily',
            careType: CareType.fertilizing,
            frequencyDays: 14,
            nextDueDate: DateTime.now().add(const Duration(days: 2)),
            notes: 'Use balanced liquid fertilizer during growth season.',
          ),
        ];
        await _save();
      }
    } catch (e) {
      debugPrint('Error loading care reminders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addReminder(PlantCareReminder reminder) async {
    _reminders.insert(0, reminder);
    notifyListeners();
    await _save();
  }

  Future<void> updateReminder(PlantCareReminder updated) async {
    final idx = _reminders.indexWhere((r) => r.id == updated.id);
    if (idx != -1) {
      _reminders[idx] = updated;
      notifyListeners();
      await _save();
    }
  }

  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    notifyListeners();
    await _save();
  }

  Future<void> markDone(String id) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final current = _reminders[idx];
      final now = DateTime.now();
      final nextDue = now.add(Duration(days: current.frequencyDays));
      _reminders[idx] = current.copyWith(
        lastCompletedDate: now,
        nextDueDate: nextDue,
      );
      notifyListeners();
      await _save();
    }
  }

  Future<void> snooze(String id, int days) async {
    final idx = _reminders.indexWhere((r) => r.id == id);
    if (idx != -1) {
      final current = _reminders[idx];
      final newDue = DateTime.now().add(Duration(days: days));
      _reminders[idx] = current.copyWith(
        nextDueDate: newDue,
      );
      notifyListeners();
      await _save();
    }
  }

  Future<void> _save() async {
    try {
      final jsonList = _reminders.map((r) => r.toJson()).toList();
      await _storage.saveRemindersRaw(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving care reminders: $e');
    }
  }
}
