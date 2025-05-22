enum Punctuation { one, two, three, four, five }

// TODO: Crear métodos postear comentario, borrar comentario, editar comentario, obtener comentarios de un servicio
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
