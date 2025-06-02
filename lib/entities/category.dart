// file: entities/category.dart
class Category {
  final String id;
  final String name;

  Category({
    required this.id,
    required this.name,
  });

  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: docId,
      name: map['name']?.toString() ?? 'Sin nombre',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
    };
  }
}
