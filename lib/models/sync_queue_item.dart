DateTime _parseTimestamp(String? dateStr) {
  if (dateStr == null) return DateTime.now();
  try {
    return DateTime.parse(dateStr);
  } catch (_) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return DateTime.now();
  }
}

class SyncQueueItem {
  final int? id;
  final String actionType;
  final String payload;
  final DateTime timestamp;
  final int retryCount;
  final String? errorMessage;

  const SyncQueueItem({
    this.id,
    required this.actionType,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
    this.errorMessage,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'actionType': actionType,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
      'errorMessage': errorMessage,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as int?,
      actionType: map['actionType'] as String,
      payload: map['payload'] as String,
      timestamp: _parseTimestamp(map['timestamp'] as String?),
      retryCount: map['retryCount'] as int? ?? 0,
      errorMessage: map['errorMessage'] as String?,
    );
  }

  SyncQueueItem copyWith({
    int? id,
    String? actionType,
    String? payload,
    DateTime? timestamp,
    int? retryCount,
    String? errorMessage,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      actionType: actionType ?? this.actionType,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
