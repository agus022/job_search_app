class Category {
  final String id;
  final String name;

  Category({required this.id, required this.name});

  factory Category.fromMap(Map<String, dynamic> map, String docId) {
    return Category(
      id: docId,
      name: map['name'] as String,
    );
  }
}

class Job {
  final String id;
  final String name;
  final String categoryName;
  final String categoryNameRef;

  Job({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryNameRef,
  });

  factory Job.fromMap(Map<String, dynamic> map, {required String docId}) {
    return Job(
      id: docId,
      name: map['name'] as String,
      categoryName: map['categoryName'] as String,
      categoryNameRef: map['categoryNameRef'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'categoryName': categoryName,
      'categoryNameRef': categoryNameRef,
    };
  }
}
