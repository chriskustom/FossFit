class BaseModel {
  int? id;
  DateTime created;

  BaseModel({this.id, DateTime? created}) : created = created ?? DateTime.now();

  /// Child classes must implement copyWith
  BaseModel copyWith({int? id, DateTime? created}) {
    throw UnimplementedError('copyWith must be implemented in subclasses');
  }
}
