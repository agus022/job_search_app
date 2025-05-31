import 'package:cloud_firestore/cloud_firestore.dart';

enum Punctuation { zero, one, two, three, four, five }

class Calification {
  final String? id;
  // final String serviceRef;
  final String clientRef;
  final Punctuation punctuation;
  final String comment;
  final DateTime date;

  Calification({
    this.id,
    // required this.serviceRef,
    required this.clientRef,
    required this.punctuation,
    required this.comment,
    required this.date,
  });

  /// Crea una instancia de Calification a partir de un Map de Firestore.
  factory Calification.fromMap(Map<String, dynamic> map, {String? docId}) {
    return Calification(
      id: docId ?? map['id'] as String?,
      // serviceRef: map['serviceRef'] as String,
      clientRef: map['clientRef'] as String,
      punctuation: Punctuation.values.firstWhere(
        (e) => e.name == (map['punctuation'] as String),
        orElse: () => Punctuation.zero,
      ),
      comment: map['comment'] as String,
      date: (map['date'] as Timestamp).toDate(),
    );
  }

  /// Convierte esta Calification a un Map para Firestore.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'serviceRef': serviceRef,
      'clientRef': clientRef,
      'punctuation': punctuation.name,
      'comment': comment,
      'date': Timestamp.fromDate(date),
    };
  }
}
