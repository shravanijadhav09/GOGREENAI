class FeedbackModel {
  final String id;
  final int rating;
  final String? comment;
  final String? orderId;
  final String nurseryId;
  final String userId;
  final String? userName;
  final String? userAvatarUrl;
  final DateTime createdAt;

  const FeedbackModel({
    required this.id,
    required this.rating,
    this.comment,
    this.orderId,
    required this.nurseryId,
    required this.userId,
    this.userName,
    this.userAvatarUrl,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    String? name;
    String? avatar;
    if (json['user'] is Map<String, dynamic>) {
      final u = json['user'] as Map<String, dynamic>;
      final first = u['firstName'] as String? ?? '';
      final last = u['lastName'] as String? ?? '';
      name = '$first $last'.trim();
      if (name.isEmpty) name = 'Verified Customer';
      avatar = u['avatarUrl'] as String?;
    }

    DateTime parsedDate;
    try {
      parsedDate = json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return FeedbackModel(
      id: json['id'] as String? ?? '',
      rating: (json['rating'] as int?) ?? 5,
      comment: json['comment'] as String?,
      orderId: json['orderId'] as String?,
      nurseryId: json['nurseryId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      userName: name ?? 'Verified Customer',
      userAvatarUrl: avatar,
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'rating': rating,
      'comment': comment,
      'orderId': orderId,
      'nurseryId': nurseryId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
