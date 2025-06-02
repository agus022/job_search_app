import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String name;
  final String categoryName;
  final DocumentReference categoryNameRef;

  Job({
    required this.id,
    required this.name,
    required this.categoryName,
    required this.categoryNameRef,
  });

  factory Job.fromMap(Map<String, dynamic> map, String id,
      {required String docId}) {
    return Job(
      id: id,
      name: map['name']?.toString() ?? 'Sin nombre',
      categoryName: map['categoryName']?.toString() ?? '',
      categoryNameRef: map['categoryNameRef'] is DocumentReference
          ? map['categoryNameRef'] as DocumentReference
          : FirebaseFirestore.instance
              .doc(map['categoryNameRef']?.toString() ?? ''),
    );
  }
}
