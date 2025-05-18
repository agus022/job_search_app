enum Punctuation { one, two, three, four, five }

class Calification {
  final String? id;
  final String serviceRef;
  final String clientRef;
  final String oficialRef;
  final Punctuation punctuation;
  final String comment;
  final DateTime date;

  Calification({
    this.id,
    required this.serviceRef,
    required this.clientRef,
    required this.oficialRef,
    required this.punctuation,
    required this.comment,
    required this.date,
  });
}
