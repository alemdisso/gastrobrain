class Tag {
  final String id;
  final String name;
  final String typeId;

  const Tag({
    required this.id,
    required this.name,
    required this.typeId,
  });

  factory Tag.fromMap(Map<String, dynamic> map) {
    return Tag(
      id: map['id'] as String,
      name: map['name'] as String,
      typeId: map['type_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type_id': typeId,
    };
  }

  Tag copyWith({
    String? id,
    String? name,
    String? typeId,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Tag && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Tag($id, name: $name, typeId: $typeId)';
}
