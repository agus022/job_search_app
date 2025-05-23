enum Punctuation { one, two, three, four, five }

class Calification {
  final String? id;
  final String serviceRef;
  final String clientRef;
  final Punctuation punctuation;
  final String comment;
  final DateTime date;

  Calification({
    this.id,
    required this.serviceRef,
    required this.clientRef,
    required this.punctuation,
    required this.comment,
    required this.date,
  });
}
