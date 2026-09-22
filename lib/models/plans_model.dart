class Plan {
  int? id;
  final String days;
  final int? sequence;
  final String? title;
  Plan({
    this.id,
    required this.days,
    this.sequence,
    required this.title,
  });

  Plan copyWith({
    int? id,
    String? days,
    int? sequence,
    String? title,
  }) {
    return Plan(
      id: id ?? this.id,
      days: days ?? this.days,
      sequence: sequence ?? this.sequence,
      title: title ?? this.title,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'days': days,
        'sequence': sequence,
        'title': title,
      };

  factory Plan.fromMap(Map<String, dynamic> map) {
    return Plan(
      id: map['id'],
      days: map['days'],
      sequence: map['sequence'],
      title: map['title'],
    );
  }
}
