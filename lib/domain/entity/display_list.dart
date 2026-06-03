class DisplayList {
  const DisplayList({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.colorKey,
    required this.memberIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String ownerId;
  final String colorKey;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  DisplayList copyWith({
    String? id,
    String? name,
    String? ownerId,
    String? colorKey,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DisplayList(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      colorKey: colorKey ?? this.colorKey,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
