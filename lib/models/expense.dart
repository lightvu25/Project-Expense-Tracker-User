enum ExpenseCategory {
  travel,
  equipment,
  materials,
  services,
  software,
  labor,
  utilities,
  miscellaneous,
}

extension ExpenseCategoryExtension on ExpenseCategory {
  String get displayName {
    switch (this) {
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.equipment:
        return 'Equipment';
      case ExpenseCategory.materials:
        return 'Materials';
      case ExpenseCategory.services:
        return 'Services';
      case ExpenseCategory.software:
        return 'Software/Licenses';
      case ExpenseCategory.labor:
        return 'Labour costs';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.miscellaneous:
        return 'Miscellaneous';
    }
  }

  String get icon {
    switch (this) {
      case ExpenseCategory.travel:
        return '✈️';
      case ExpenseCategory.equipment:
        return '🔧';
      case ExpenseCategory.materials:
        return '🛒';
      case ExpenseCategory.services:
        return '🔼';
      case ExpenseCategory.software:
        return '💻';
      case ExpenseCategory.labor:
        return '👷';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.miscellaneous:
        return '📦';
    }
  }

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.displayName == value || e.name == value,
      orElse: () => ExpenseCategory.miscellaneous,
    );
  }
}

DateTime _parseDate(String? dateStr) {
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

class Expense {
  final String id;
  final DateTime date;
  final double amount;
  final String currency;
  final ExpenseCategory category;
  final String paymentMethod;
  final String claimant;
  final String paymentStatus;
  final String? title;
  final String? description;
  final String? location;
  final String? imageUrl;
  final String projectId;

  const Expense({
    required this.id,
    required this.date,
    required this.amount,
    this.currency = 'USD',
    required this.category,
    this.paymentMethod = 'Cash',
    this.claimant = '',
    this.paymentStatus = 'Pending',
    this.title,
    this.description,
    this.location,
    this.imageUrl,
    required this.projectId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'amount': amount,
      'currency': currency,
      'category': category.name,
      'paymentMethod': paymentMethod,
      'claimant': claimant,
      'paymentStatus': paymentStatus,
      'title': title,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'projectId': projectId,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] as String? ?? '',
      date: _parseDate(map['date'] as String?),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'USD',
      category: ExpenseCategoryExtension.fromString(
        map['category'] as String? ?? '',
      ),
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      claimant: map['claimant'] as String? ?? '',
      paymentStatus: map['paymentStatus'] as String? ?? 'Pending',
      title: map['title'] as String?,
      description: map['description'] as String?,
      location: map['location'] as String?,
      imageUrl: map['imageUrl'] as String?,
      projectId: map['projectId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Expense.fromJson(Map<String, dynamic> json) => Expense.fromMap(json);

  Expense copyWith({
    String? id,
    DateTime? date,
    double? amount,
    String? currency,
    ExpenseCategory? category,
    String? paymentMethod,
    String? claimant,
    String? paymentStatus,
    String? title,
    String? description,
    String? location,
    String? imageUrl,
    String? projectId,
  }) {
    return Expense(
      id: id ?? this.id,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      claimant: claimant ?? this.claimant,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      projectId: projectId ?? this.projectId,
    );
  }
}
