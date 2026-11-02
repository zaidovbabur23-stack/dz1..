class Note {
  const Note({
    required this.title,
    required this.description,
    this.category = 'Личное',
    this.colorIndex = 0,
    this.isFavorite = false,
    required this.createdAt,
  });

  final String title;
  final String description;
  final String category;
  final int colorIndex;
  final bool isFavorite;
  final DateTime createdAt;

  Note copyWith({
    String? title,
    String? description,
    String? category,
    int? colorIndex,
    bool? isFavorite,
    DateTime? createdAt,
  }) {
    return Note(
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      colorIndex: colorIndex ?? this.colorIndex,
      isFavorite: isFavorite ?? this.isFavorite,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
