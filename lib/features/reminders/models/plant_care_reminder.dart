enum CareType {
  watering,
  fertilizing,
  repotting,
  pruning;

  String get label {
    switch (this) {
      case CareType.watering:
        return 'Watering';
      case CareType.fertilizing:
        return 'Fertilizing';
      case CareType.repotting:
        return 'Repotting';
      case CareType.pruning:
        return 'Pruning';
    }
  }

  String get emoji {
    switch (this) {
      case CareType.watering:
        return '💧';
      case CareType.fertilizing:
        return '🌿';
      case CareType.repotting:
        return '🪴';
      case CareType.pruning:
        return '✂️';
    }
  }

  static CareType fromString(String? val) {
    if (val == null) return CareType.watering;
    switch (val.toUpperCase()) {
      case 'FERTILIZING':
        return CareType.fertilizing;
      case 'REPOTTING':
        return CareType.repotting;
      case 'PRUNING':
        return CareType.pruning;
      default:
        return CareType.watering;
    }
  }
}

class PlantCareReminder {
  final String id;
  final String plantName;
  final String? plantId;
  final String? imageUrl;
  final CareType careType;
  final int frequencyDays; // e.g. 1 for daily, 3 for every 3 days, 7 for weekly
  final DateTime nextDueDate;
  final DateTime? lastCompletedDate;
  final String? notes;

  const PlantCareReminder({
    required this.id,
    required this.plantName,
    this.plantId,
    this.imageUrl,
    required this.careType,
    required this.frequencyDays,
    required this.nextDueDate,
    this.lastCompletedDate,
    this.notes,
  });

  bool get isDueToday {
    final now = DateTime.now();
    return nextDueDate.year == now.year &&
        nextDueDate.month == now.month &&
        nextDueDate.day == now.day;
  }

  bool get isOverdue {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.isBefore(today);
  }

  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(nextDueDate.year, nextDueDate.month, nextDueDate.day);
    return due.difference(today).inDays;
  }

  String get dueStatusText {
    if (isOverdue) {
      final days = daysRemaining.abs();
      return days == 1 ? 'Overdue by 1 day' : 'Overdue by $days days';
    } else if (isDueToday) {
      return 'Due Today';
    } else {
      final days = daysRemaining;
      return days == 1 ? 'Due tomorrow' : 'Due in $days days';
    }
  }

  PlantCareReminder copyWith({
    String? id,
    String? plantName,
    String? plantId,
    String? imageUrl,
    CareType? careType,
    int? frequencyDays,
    DateTime? nextDueDate,
    DateTime? lastCompletedDate,
    String? notes,
  }) {
    return PlantCareReminder(
      id: id ?? this.id,
      plantName: plantName ?? this.plantName,
      plantId: plantId ?? this.plantId,
      imageUrl: imageUrl ?? this.imageUrl,
      careType: careType ?? this.careType,
      frequencyDays: frequencyDays ?? this.frequencyDays,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantName': plantName,
      'plantId': plantId,
      'imageUrl': imageUrl,
      'careType': careType.name,
      'frequencyDays': frequencyDays,
      'nextDueDate': nextDueDate.toIso8601String(),
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'notes': notes,
    };
  }

  factory PlantCareReminder.fromJson(Map<String, dynamic> json) {
    return PlantCareReminder(
      id: json['id'] as String,
      plantName: json['plantName'] as String,
      plantId: json['plantId'] as String?,
      imageUrl: json['imageUrl'] as String?,
      careType: CareType.fromString(json['careType'] as String?),
      frequencyDays: (json['frequencyDays'] as num?)?.toInt() ?? 3,
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }
}
