import 'package:equatable/equatable.dart';

/// نموذج بيانات الإشعار المحفوظ داخلياً (In-App Notification Model)
class InAppNotificationModel extends Equatable {
  final int? id;
  final String title;
  final String body;
  final String type; // 'budget', 'reminder', 'recurring', 'system'
  final DateTime createdAt;
  final bool isRead;

  const InAppNotificationModel({
    this.id,
    required this.title,
    required this.body,
    this.type = 'system',
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'body': body,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory InAppNotificationModel.fromMap(Map<String, dynamic> map) {
    return InAppNotificationModel(
      id: map['id'] as int?,
      title: map['title'] as String,
      body: map['body'] as String,
      type: (map['type'] as String?) ?? 'system',
      createdAt: DateTime.parse(map['created_at'] as String),
      isRead: (map['is_read'] as int? ?? 0) == 1,
    );
  }

  InAppNotificationModel copyWith({
    int? id,
    String? title,
    String? body,
    String? type,
    DateTime? createdAt,
    bool? isRead,
  }) {
    return InAppNotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  @override
  List<Object?> get props => [id, title, body, type, createdAt, isRead];
}
